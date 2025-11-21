@echo off
setlocal EnableDelayedExpansion

:: ---------------------------------------------------------
:: 1. Validate Arguments
:: ---------------------------------------------------------
set "INPUT_FILE=%~1"

if "%INPUT_FILE%"=="" (
    echo Error: No input script specified.
    echo Usage: %~nx0 "path\to\perl_script"
    pause
    exit /b 1
)

if not exist "%INPUT_FILE%" (
    echo Error: Input file not found: "%INPUT_FILE%"
    pause
    exit /b 1
)

:: Prepare path variables for the target file
:: Get absolute path of input
set "TARGET_FULL=%~f1"
:: Get directory of input
set "TARGET_DIR=%~dp1"
:: Get filename without extension
set "TARGET_NAME=%~n1"

:: Convert target paths to forward slashes for Perl consistency
set "TARGET_FULL_FWD=!TARGET_FULL:\=/!"
set "TARGET_DIR_FWD=!TARGET_DIR:\=/!"
set "OUTPUT_EXE=!TARGET_DIR_FWD!!TARGET_NAME!.exe"

:: ---------------------------------------------------------
:: 2. Environment Setup & Path Optimization
:: ---------------------------------------------------------

:: Change directory to the location of this script
cd /d "%~dp0"

:: Convert the current Windows path to use Forward Slashes
set "RAW_BASE=%~dp0"
set "BASE_PATH=!RAW_BASE:\=/!"

echo --- Optimizing PATH (Deprioritizing MSYS) ---
set "CLEAN_PATH="
set "MSYS_PATH="

:: Iterate through PATH to separate MSYS/Cygwin entries
for %%a in ("%PATH:;=" "%") do (
    set "SEGMENT=%%~a"
    set "SEGMENT=!SEGMENT:"=!"
    if not "!SEGMENT!"=="" (
        echo "!SEGMENT!" | findstr /I "msys cygwin" >nul
        if !errorlevel! equ 0 (
            set "MSYS_PATH=!MSYS_PATH!;!SEGMENT!"
        ) else (
            set "CLEAN_PATH=!CLEAN_PATH!;!SEGMENT!"
        )
    )
)

:: Reassemble PATH: Put clean Windows paths first, MSYS last
if defined CLEAN_PATH set "CLEAN_PATH=!CLEAN_PATH:~1!"
if defined MSYS_PATH set "MSYS_PATH=!MSYS_PATH:~1!"
if defined CLEAN_PATH (
    set "PATH=!CLEAN_PATH!;!MSYS_PATH!"
) else (
    set "PATH=!MSYS_PATH!"
)

:: Define local library paths (Relative to the batch file)
set "LOCAL_LIB=./perl_lib"

:: Set environment variables to use the local library
set "PERL5LIB=!LOCAL_LIB!/lib/perl5;%PERL5LIB%"
set "PATH=!LOCAL_LIB!/bin;%PATH%"

:: Prevent CPAN from asking questions (Auto-yes)
set "PERL_MM_USE_DEFAULT=1"

echo.
echo --- Checking for Perl ---
perl -v >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Perl is not installed.
    pause
    exit /b 1
)

echo --- Checking for PAR::Packer ---
:: Check if PAR::Packer is loadable globally
perl -e "use PAR::Packer" >nul 2>&1
if %errorlevel% equ 0 (
    echo PAR::Packer is already installed globally.
    set "PP_CMD=perl -S pp"
) else (
    :: Check if we already installed it locally
    if exist "!LOCAL_LIB!/bin/pp" (
        echo PAR::Packer found in local lib.
        set "PP_CMD=perl "!LOCAL_LIB!/bin/pp""
    ) else (
        echo PAR::Packer not found. Preparing local install ^(Tests Skipped^)...
        
        :: 1. Ensure App::cpanminus (cpanm) is available
        perl -MApp::cpanminus -e 1 >nul 2>&1
        if %errorlevel% neq 0 (
            echo 'cpanm' helper not found. Installing via standard CPAN...
            :: We use standard call here for bootstrapping
            perl -MCPAN -e "CPAN::Shell->notest('install', 'App::cpanminus')"
        )

        :: 2. Install PAR::Packer into local directory using cpanm wrapper
        echo Installing PAR::Packer into "!LOCAL_LIB!"...
        :: Use forward slashes in argument
        perl -S cpanm --notest -L "!LOCAL_LIB!" PAR::Packer
        
        if errorlevel 1 (
            echo Error: Failed to install PAR::Packer.
            pause
            exit /b 1
        )
        
        set "PP_CMD=perl "!LOCAL_LIB!/bin/pp""
    )
)

echo.
echo --- Building Executable ---
echo Input:  !TARGET_FULL_FWD!
echo Output: !OUTPUT_EXE!
echo.

:: Compile the specific script passed as argument
%PP_CMD% -o "!OUTPUT_EXE!" "!TARGET_FULL_FWD!"

if errorlevel 1 (
    echo.
    echo Error: Compilation failed.
    pause
    exit /b 1
)

echo.
echo ------------------------------------------
echo Build Complete.
echo File created at: !OUTPUT_EXE!
echo ------------------------------------------