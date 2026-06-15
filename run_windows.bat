@echo off
cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
    echo Ambiente non trovato. Esegui prima setup_windows.bat
    echo.
    pause
    exit /b 1
)

".venv\Scripts\python.exe" main.py
pause
