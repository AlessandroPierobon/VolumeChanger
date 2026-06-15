# Controllo Volume con la Mano

Programma Python che usa la webcam per riconoscere la mano e regolare il volume
di sistema in base alla distanza tra **pollice** e **indice**: piu allontani le
due dita, piu il volume aumenta; piu le avvicini, piu diminuisce.

Funziona su **macOS** e **Windows**.

## Come funziona

1. La webcam cattura il video (OpenCV).
2. [MediaPipe](https://ai.google.dev/edge/mediapipe) individua i 21 punti della mano.
3. Si misura la distanza tra la punta del pollice (punto 4) e dell'indice (punto 8),
   normalizzata sulla dimensione del palmo per essere stabile anche se avvicini o
   allontani la mano dalla camera.
4. La distanza viene mappata sul volume di sistema (0-100) e applicata con:
   - **macOS**: `osascript` (AppleScript), gia incluso nel sistema.
   - **Windows**: la libreria `pycaw` (API audio di Windows).

## Requisiti

- macOS oppure Windows
- **Python 3.12** — MediaPipe non e ancora compatibile con Python 3.13/3.14.

---

## Windows (installazione automatica)

Sono inclusi due script che fanno tutto da soli.

1. **Doppio clic su `setup_windows.bat`**: installa Python 3.12 (se manca, via
   winget o scaricando l'installer ufficiale), crea l'ambiente virtuale `.venv`
   e installa tutte le librerie.
2. **Doppio clic su `run_windows.bat`**: avvia il programma.

> Se `setup_windows.bat` installa Python da zero, alla fine puo essere
> necessario chiudere e riaprire la finestra una volta (per aggiornare il PATH)
> e rilanciare lo script.

Permessi: la prima volta concedi l'accesso alla **Fotocamera** in
`Impostazioni > Privacy e sicurezza > Fotocamera`.

---

## Avvio con doppio clic (senza terminale)

- **macOS**: fai doppio clic su **`Avvia VolumeChanger.command`**. Al primo
  avvio esegue da solo il setup (installazione componenti), poi lancia il
  programma. Le volte successive parte direttamente.
- **Windows**: fai doppio clic su **`run_windows.bat`** (dopo aver eseguito una
  volta `setup_windows.bat`).

> Nota macOS: la prima volta, se compare l'avviso di sicurezza, fai clic destro
> sul file > **Apri** > **Apri**. In alternativa: `Impostazioni di Sistema >
> Privacy e Sicurezza > Apri comunque`.

## macOS / Linux (installazione automatica)

Sono inclusi due script che fanno tutto da soli (analoghi a quelli Windows).

```bash
./setup_unix.sh   # installa Python 3.12 se manca, crea .venv e installa le librerie
./run_unix.sh     # avvia il programma
```

> Se gli script non sono eseguibili: `chmod +x setup_unix.sh run_unix.sh`.

Cosa fa `setup_unix.sh`:
- **macOS**: installa Python 3.12 con Homebrew (richiede Homebrew gia presente,
  vedi https://brew.sh).
- **Linux**: installa Python 3.12 con il gestore pacchetti rilevato
  (`apt` con fallback al PPA deadsnakes, `dnf`) e le librerie di sistema per
  OpenCV. Potrebbe chiedere la password `sudo`.

Permessi: la prima volta concedi l'accesso alla **Fotocamera**
(macOS: `Privacy e Sicurezza > Fotocamera`).

---

## macOS (installazione manuale)

In alternativa allo script, tutti i comandi vanno eseguiti nella cartella del progetto.

### 1. Installa Python 3.12 (con Homebrew)

```bash
brew install python@3.12
```

### 2. Crea e attiva un ambiente virtuale

```bash
/opt/homebrew/bin/python3.12 -m venv .venv
source .venv/bin/activate
```

> Da ora il prompt mostra `(.venv)`. Per disattivarlo: `deactivate`.

### 3. Installa le librerie

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### Avvio (macOS)

```bash
source .venv/bin/activate   # se non gia attivo
python main.py
```

Si apre una finestra con il video della webcam. Mostra la mano alla camera,
avvicina o allontana pollice e indice per cambiare il volume. Premi **`q`**
per uscire.

## Permessi macOS (importante)

Alla prima esecuzione macOS chiede l'accesso alla **Camera**: concedilo all'app
da cui lanci lo script (Terminale, iTerm oppure Cursor/VS Code).

Se il popup non compare o la webcam non si apre:

1. Apri **Impostazioni di Sistema > Privacy e Sicurezza > Fotocamera**.
2. Attiva l'app che usi per eseguire lo script.
3. Riavvia l'app e riprova.

Per il volume non servono permessi: `osascript` e integrato in macOS.

## Estensioni editor (opzionale)

Nessuna estensione obbligatoria. In Cursor/VS Code e consigliata l'estensione
**Python** di Microsoft: seleziona l'interprete `.venv` (comando
"Python: Select Interpreter") per autocompletamento e debug.

## Personalizzazione

In `main.py` puoi regolare:

- `MIN_RATIO` / `MAX_RATIO`: la sensibilita del gesto (rapporto distanza dita /
  dimensione palmo che corrisponde a volume 0 e 100).
- `SMOOTHING`: quanto e fluido/reattivo il cambio di volume (0-1).
