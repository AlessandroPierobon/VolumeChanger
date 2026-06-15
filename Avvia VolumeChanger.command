#!/usr/bin/env bash
# Doppio clic su questo file per avviare il programma su macOS.
# Se l'ambiente non e ancora installato, esegue prima il setup automatico.

cd "$(dirname "$0")" || exit 1

if [ ! -x ".venv/bin/python" ]; then
    echo "Primo avvio: installo i componenti necessari..."
    echo
    if [ -x "./setup_unix.sh" ]; then
        bash "./setup_unix.sh" || {
            echo
            echo "Installazione non riuscita. Premi Invio per chiudere."
            read -r _
            exit 1
        }
    else
        echo "ERRORE: setup_unix.sh non trovato."
        read -r _
        exit 1
    fi
fi

echo
echo "Avvio del programma... (premi 'q' nella finestra video per uscire)"
./.venv/bin/python main.py

# Mantieni la finestra aperta se il programma termina con errore.
status=$?
if [ "$status" -ne 0 ]; then
    echo
    echo "Il programma e terminato con un errore (codice $status)."
    echo "Premi Invio per chiudere."
    read -r _
fi
