@echo off
setlocal

:: Change directory to the location of this script
cd /d "%~dp0"

:: restore uncleaned path if exists
if defined WLB_PATH_ORIG set "PATH=%WLB_PATH_ORIG%;%PATH%"

:: 1. Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Python is not installed or not in your PATH.
    exit /b 1
)

:: ---------------------------------------------------------
:: VENV LOGIC START
:: ---------------------------------------------------------

:: Check if the environment variable is already set (e.g., via bash script)
if defined PATCHVIEW_VENV (
    echo PATCHVIEW_VENV variable detected. Skipping bat file venv creation/activation.
    goto :install_and_build
)

:: Check for MSYS/Bash specific venv structure (bin/activate exists, but Scripts/activate.bat does not)
if not exist "venv\Scripts\activate.bat" (
    if exist "venv\bin\activate" (
        echo.
        echo Error: A virtual environment created in MSYS/Bash was detected.
        echo Please run 'patchview-wrapper-to-exe.sh' instead.
        echo.
        exit /b 1
    )
)

:: 2. Create virtual environment 'venv' if it doesn't exist (Standard Windows)
if exist "venv\Scripts\activate.bat" (
    echo Virtual environment 'venv' found. Skipping creation.
) else (
    echo Creating virtual environment 'venv'...
    python -m venv venv
    if %errorlevel% neq 0 (
        echo Failed to create virtual environment.
        exit /b 1
    )
)

:: 3. Activate the virtual environment
call venv\Scripts\activate.bat

:: Set the variable to indicate activation is complete
set PATCHVIEW_VENV=1

:: ---------------------------------------------------------
:: VENV LOGIC END
:: ---------------------------------------------------------

:install_and_build

:: 4. Install PyInstaller (will skip if already satisfied)
echo Installing PyInstaller...
python -m ensurepip
python -m pip install pyinstaller
if %errorlevel% neq 0 (
    echo Failed to install PyInstaller.
    exit /b 1
)

:: 5. Run PyInstaller with your specific flags
:: %~dp0 expands to the drive and path of this script.
echo Running PyInstaller on patchview-wrapper...
pyinstaller --noconfirm --onefile --console --distpath "%~dp0." "%~dp0patchview-wrapper"
if %errorlevel% neq 0 (
    echo PyInstaller build failed.
    exit /b 1
)

echo.
echo ------------------------------------------
echo Build Complete.
echo ------------------------------------------