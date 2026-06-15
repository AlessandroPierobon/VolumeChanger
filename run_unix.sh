#!/usr/bin/env bash
# Avvia il programma su macOS/Linux usando l'ambiente virtuale .venv.

cd "$(dirname "$0")"

if [ ! -x ".venv/bin/python" ]; then
    echo "Ambiente non trovato. Esegui prima ./setup_unix.sh"
    exit 1
fi

./.venv/bin/python main.py
