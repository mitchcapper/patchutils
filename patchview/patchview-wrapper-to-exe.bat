@echo off
setlocal

:: Change directory to the location of this script
cd /d "%~dp0"

:: 1. Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Python is not installed or not in your PATH.
    pause
    exit /b 1
)

:: 2. Create virtual environment 'venv' if it doesn't exist
if exist "venv\Scripts\activate.bat" (
    echo Virtual environment 'venv' found. Skipping creation.
) else (
    echo Creating virtual environment 'venv'...
    python -m venv venv
    if %errorlevel% neq 0 (
        echo Failed to create virtual environment.
        pause
        exit /b 1
    )
)

:: 3. Activate the virtual environment
call venv\Scripts\activate.bat

:: 4. Install PyInstaller (will skip if already satisfied)
echo Installing PyInstaller...
pip install pyinstaller

:: 5. Run PyInstaller with your specific flags
:: %~dp0 expands to the drive and path of this script.
echo Running PyInstaller on patchview-wrapper...
pyinstaller --noconfirm --onefile --console --distpath "%~dp0." "%~dp0patchview-wrapper"

echo.
echo ------------------------------------------
echo Build Complete.
echo ------------------------------------------
