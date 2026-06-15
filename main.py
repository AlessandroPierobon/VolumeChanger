"""Controllo del volume di sistema tramite la webcam (macOS e Windows).

Riconosce la mano con MediaPipe e regola il volume in base alla distanza tra
la punta del pollice e quella dell'indice: piu sono lontani, piu alto e il
volume. Premere "q" per uscire.

Il controllo del volume e multipiattaforma:
- macOS: usa "osascript" (AppleScript), gia incluso nel sistema.
- Windows: usa la libreria "pycaw" (API audio di Windows).
"""

import math
import platform
import subprocess
import time

import cv2
import mediapipe as mp
import numpy as np

SYSTEM = platform.system()

# La distanza tra pollice e indice viene normalizzata sulla larghezza del
# palmo, cosi il controllo resta stabile anche allontanando/avvicinando la
# mano alla camera. Questi due valori definiscono il rapporto minimo (volume 0)
# e massimo (volume 100). Vanno tarati a piacere.
MIN_RATIO = 0.4
MAX_RATIO = 2.0

SMOOTHING = 0.35  # 0 = nessuno smoothing, vicino a 1 = molto reattivo


_win_volume = None


def _get_win_volume_interface():
    """Restituisce (e crea una sola volta) l'interfaccia audio di Windows."""
    global _win_volume
    if _win_volume is None:
        from ctypes import POINTER, cast

        from comtypes import CLSCTX_ALL
        from pycaw.pycaw import AudioUtilities, IAudioEndpointVolume

        devices = AudioUtilities.GetSpeakers()
        interface = devices.Activate(IAudioEndpointVolume._iid_, CLSCTX_ALL, None)
        _win_volume = cast(interface, POINTER(IAudioEndpointVolume))
    return _win_volume


def set_system_volume(volume: int) -> None:
    """Imposta il volume di output di sistema (0-100)."""
    volume = int(max(0, min(100, volume)))
    if SYSTEM == "Darwin":
        subprocess.run(
            ["osascript", "-e", f"set volume output volume {volume}"],
            check=False,
        )
    elif SYSTEM == "Windows":
        _get_win_volume_interface().SetMasterVolumeLevelScalar(volume / 100.0, None)
    else:
        raise RuntimeError(f"Sistema operativo non supportato: {SYSTEM}")


def get_system_volume() -> int:
    """Legge il volume di output corrente di sistema (0-100)."""
    try:
        if SYSTEM == "Darwin":
            result = subprocess.run(
                ["osascript", "-e", "output volume of (get volume settings)"],
                capture_output=True,
                text=True,
                check=True,
            )
            return int(result.stdout.strip())
        if SYSTEM == "Windows":
            scalar = _get_win_volume_interface().GetMasterVolumeLevelScalar()
            return int(round(scalar * 100))
    except Exception:
        pass
    return 50


def main() -> None:
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        raise RuntimeError(
            "Impossibile aprire la webcam. Controlla i permessi della "
            "Fotocamera nelle impostazioni del sistema operativo "
            "(macOS: Privacy e Sicurezza > Fotocamera; "
            "Windows: Privacy e sicurezza > Fotocamera)."
        )

    mp_hands = mp.solutions.hands
    mp_draw = mp.solutions.drawing_utils
    mp_styles = mp.solutions.drawing_styles

    hands = mp_hands.Hands(
        max_num_hands=1,
        model_complexity=0,
        min_detection_confidence=0.6,
        min_tracking_confidence=0.6,
    )

    # Partiamo dal volume reale del sistema per evitare salti all'avvio.
    smoothed_volume = float(get_system_volume())
    last_sent_volume = -1
    last_send_time = 0.0

    try:
        while True:
            ok, frame = cap.read()
            if not ok:
                break

            # Specchia il frame: piu intuitivo, come uno specchio.
            frame = cv2.flip(frame, 1)
            h, w = frame.shape[:2]

            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            rgb.flags.writeable = False
            results = hands.process(rgb)

            target_volume = smoothed_volume

            if results.multi_hand_landmarks:
                hand = results.multi_hand_landmarks[0]
                mp_draw.draw_landmarks(
                    frame,
                    hand,
                    mp_hands.HAND_CONNECTIONS,
                    mp_styles.get_default_hand_landmarks_style(),
                    mp_styles.get_default_hand_connections_style(),
                )

                lm = hand.landmark
                thumb = lm[4]   # punta del pollice
                index = lm[8]   # punta dell'indice
                wrist = lm[0]
                index_mcp = lm[5]  # base dell'indice

                thumb_px = (int(thumb.x * w), int(thumb.y * h))
                index_px = (int(index.x * w), int(index.y * h))

                # Distanza pollice-indice e dimensione del palmo (per normalizzare).
                pinch = math.hypot(thumb.x - index.x, thumb.y - index.y)
                palm = math.hypot(wrist.x - index_mcp.x, wrist.y - index_mcp.y)
                ratio = pinch / palm if palm > 1e-6 else 0.0

                target_volume = float(
                    np.interp(ratio, [MIN_RATIO, MAX_RATIO], [0, 100])
                )

                # Disegna la linea pollice-indice e i due punti.
                cv2.line(frame, thumb_px, index_px, (0, 255, 0), 3)
                cv2.circle(frame, thumb_px, 10, (255, 0, 255), cv2.FILLED)
                cv2.circle(frame, index_px, 10, (255, 0, 255), cv2.FILLED)
                mid = ((thumb_px[0] + index_px[0]) // 2,
                       (thumb_px[1] + index_px[1]) // 2)
                cv2.circle(frame, mid, 8, (0, 255, 0), cv2.FILLED)

            # Smoothing esponenziale per evitare sbalzi del volume.
            smoothed_volume += (target_volume - smoothed_volume) * SMOOTHING
            volume_int = int(round(smoothed_volume))

            # Invia il comando solo se il valore cambia, al massimo ~ogni 80 ms.
            now = time.time()
            if volume_int != last_sent_volume and now - last_send_time > 0.08:
                set_system_volume(volume_int)
                last_sent_volume = volume_int
                last_send_time = now

            draw_volume_bar(frame, volume_int)

            cv2.imshow("Controllo Volume con la Mano - premi 'q' per uscire", frame)
            if cv2.waitKey(1) & 0xFF == ord("q"):
                break
    finally:
        hands.close()
        cap.release()
        cv2.destroyAllWindows()


def draw_volume_bar(frame, volume: int) -> None:
    """Disegna una barra verticale del volume con la percentuale."""
    h = frame.shape[0]
    x1, y1, x2, y2 = 40, 80, 80, h - 80
    cv2.rectangle(frame, (x1, y1), (x2, y2), (255, 255, 255), 2)

    fill_top = int(np.interp(volume, [0, 100], [y2, y1]))
    cv2.rectangle(frame, (x1, fill_top), (x2, y2), (0, 255, 0), cv2.FILLED)
    cv2.putText(
        frame,
        f"{volume}%",
        (x1 - 5, y2 + 40),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.8,
        (255, 255, 255),
        2,
    )


if __name__ == "__main__":
    main()
