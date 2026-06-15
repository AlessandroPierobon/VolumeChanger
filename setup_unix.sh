#!/usr/bin/env bash
#
# Setup per macOS e Linux.
# Installa Python 3.12 (se manca), crea l'ambiente virtuale .venv e installa
# le dipendenze. Analogo a setup_windows.bat.

set -u
cd "$(dirname "$0")"

echo "=================================================="
echo "  Controllo Volume con la Mano - Setup macOS/Linux"
echo "=================================================="
echo

PYTHON_BIN=""

find_python() {
    # Cerca un interprete Python 3.12 tra i comandi noti e i percorsi Homebrew.
    local cand ver
    for cand in python3.12 python3 python; do
        if command -v "$cand" >/dev/null 2>&1; then
            ver="$("$cand" -c 'import sys; print("%d.%d" % sys.version_info[:2])' 2>/dev/null || echo "")"
            if [ "$ver" = "3.12" ]; then
                PYTHON_BIN="$cand"
                return 0
            fi
        fi
    done
    if [ -x /opt/homebrew/opt/python@3.12/bin/python3.12 ]; then
        PYTHON_BIN=/opt/homebrew/opt/python@3.12/bin/python3.12
        return 0
    fi
    if [ -x /usr/local/opt/python@3.12/bin/python3.12 ]; then
        PYTHON_BIN=/usr/local/opt/python@3.12/bin/python3.12
        return 0
    fi
    return 1
}

OS="$(uname -s)"

if ! find_python; then
    echo "Python 3.12 non trovato. Provo a installarlo automaticamente..."
    echo
    case "$OS" in
        Darwin)
            if ! command -v brew >/dev/null 2>&1; then
                echo "ERRORE: Homebrew non e installato."
                echo "Installa Homebrew da https://brew.sh e poi rilancia questo script."
                exit 1
            fi
            brew install python@3.12 || { echo "ERRORE durante 'brew install python@3.12'."; exit 1; }
            ;;
        Linux)
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update
                if ! sudo apt-get install -y python3.12 python3.12-venv; then
                    echo "python3.12 non disponibile nei repo: aggiungo il PPA deadsnakes (Ubuntu)..."
                    sudo apt-get install -y software-properties-common
                    sudo add-apt-repository -y ppa:deadsnakes/ppa
                    sudo apt-get update
                    sudo apt-get install -y python3.12 python3.12-venv
                fi
                # Librerie di sistema richieste da OpenCV (GUI/video).
                sudo apt-get install -y libgl1 libglib2.0-0 || true
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y python3.12 || { echo "ERRORE: installa python3.12 manualmente."; exit 1; }
                sudo dnf install -y mesa-libGL || true
            elif command -v pacman >/dev/null 2>&1; then
                echo "Su Arch Linux installa Python 3.12 manualmente (es. pacchetto AUR 'python312')"
                echo "e poi rilancia questo script."
                exit 1
            else
                echo "ERRORE: gestore pacchetti non riconosciuto."
                echo "Installa Python 3.12 manualmente e rilancia questo script."
                exit 1
            fi
            ;;
        *)
            echo "ERRORE: sistema operativo non supportato ($OS)."
            exit 1
            ;;
    esac

    if ! find_python; then
        echo "ERRORE: Python 3.12 non trovato dopo l'installazione."
        echo "Installa Python 3.12 manualmente e rilancia questo script."
        exit 1
    fi
fi

echo
echo "Uso Python: $PYTHON_BIN ($("$PYTHON_BIN" --version 2>&1))"

echo
echo "Creo l'ambiente virtuale .venv ..."
"$PYTHON_BIN" -m venv .venv || { echo "ERRORE durante la creazione del venv."; exit 1; }

echo
echo "Aggiorno pip e installo le dipendenze ..."
./.venv/bin/python -m pip install --upgrade pip
./.venv/bin/python -m pip install -r requirements.txt || { echo "ERRORE durante l'installazione delle dipendenze."; exit 1; }

echo
echo "=================================================="
echo "  Setup completato!"
echo "  Avvia il programma con:  ./run_unix.sh"
echo "=================================================="
