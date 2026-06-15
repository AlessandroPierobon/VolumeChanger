@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo ==================================================
echo   Controllo Volume con la Mano - Setup Windows
echo ==================================================
echo.

set "USE_LAUNCHER=0"
set "PYEXE="

rem 1) Python 3.12 gia presente tramite il py launcher?
py -3.12 --version >nul 2>&1
if %errorlevel%==0 (
    set "USE_LAUNCHER=1"
    goto have_python
)

rem 2) Cerca in percorsi di installazione comuni
if exist "%LocalAppData%\Programs\Python\Python312\python.exe" set "PYEXE=%LocalAppData%\Programs\Python\Python312\python.exe"
if not defined PYEXE if exist "%ProgramFiles%\Python312\python.exe" set "PYEXE=%ProgramFiles%\Python312\python.exe"
if defined PYEXE goto have_python

echo Python 3.12 non trovato. Provo a installarlo automaticamente...
echo.

rem 3) Installa con winget se disponibile, altrimenti scarica l'installer ufficiale
where winget >nul 2>&1
if %errorlevel%==0 (
    echo Installazione di Python 3.12 tramite winget...
    winget install -e --id Python.Python.3.12 --accept-package-agreements --accept-source-agreements
) else (
    echo winget non disponibile. Scarico l'installer ufficiale di Python 3.12...
    set "PYINST=%TEMP%\python-3.12-installer.exe"
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.8/python-3.12.8-amd64.exe' -OutFile '%TEMP%\python-3.12-installer.exe'"
    echo Installazione silenziosa di Python 3.12...
    "%TEMP%\python-3.12-installer.exe" /quiet InstallAllUsers=0 PrependPath=1 Include_launcher=1
)

rem 4) Ricontrolla dopo l'installazione
py -3.12 --version >nul 2>&1
if %errorlevel%==0 (
    set "USE_LAUNCHER=1"
    goto have_python
)
if exist "%LocalAppData%\Programs\Python\Python312\python.exe" set "PYEXE=%LocalAppData%\Programs\Python\Python312\python.exe"
if not defined PYEXE if exist "%ProgramFiles%\Python312\python.exe" set "PYEXE=%ProgramFiles%\Python312\python.exe"
if defined PYEXE goto have_python

echo.
echo ERRORE: non riesco a trovare Python 3.12 dopo l'installazione.
echo Chiudi e riapri questa finestra (per aggiornare il PATH) e rilancia setup_windows.bat,
echo oppure installa Python 3.12 manualmente da https://www.python.org/downloads/
echo.
pause
exit /b 1

:have_python
echo.
echo Creo l'ambiente virtuale .venv ...
if "%USE_LAUNCHER%"=="1" (
    py -3.12 -m venv .venv
) else (
    "%PYEXE%" -m venv .venv
)
if not exist ".venv\Scripts\python.exe" (
    echo ERRORE durante la creazione dell'ambiente virtuale.
    pause
    exit /b 1
)

echo.
echo Aggiorno pip e installo le dipendenze ...
".venv\Scripts\python.exe" -m pip install --upgrade pip
".venv\Scripts\python.exe" -m pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo.
    echo ERRORE durante l'installazione delle dipendenze.
    pause
    exit /b 1
)

echo.
echo ==================================================
echo   Setup completato!
echo   Per avviare il programma fai doppio clic su
echo   run_windows.bat
echo ==================================================
echo.
pause
