#!/bin/bash

# Change directory to the location of this script
cd "$(dirname "$0")" || exit 1

# ---------------------------------------------------------
# PATH REORDERING
# Move MSYS paths (those NOT starting with /[letter]/) to the end 
# to prioritize external Windows python as msys one may not have compilers required.
# ---------------------------------------------------------
WIN_PATHS=""
MSYS_PATHS=""

# Read PATH into an array based on ':' delimiter
IFS=':' read -ra PATH_ENTRIES <<< "$PATH"

for entry in "${PATH_ENTRIES[@]}"; do
    # Check if path starts with /[letter]/ (e.g., /c/, /d/)
    if [[ "$entry" =~ ^/[a-zA-Z]/ ]]; then
        if [[ -z "$WIN_PATHS" ]]; then WIN_PATHS="$entry"; else WIN_PATHS="$WIN_PATHS:$entry"; fi
    else
        if [[ -z "$MSYS_PATHS" ]]; then MSYS_PATHS="$entry"; else MSYS_PATHS="$MSYS_PATHS:$entry"; fi
    fi
done

# Export the reordered path
export PATH="$WIN_PATHS:$MSYS_PATHS"


# Check for the specific MSYS/Bash mismatch:
# 1. venv/bin/activate exists (Unix style)
# 2. venv/Scripts/activate.bat does NOT exist (Windows style)
if [[ -f "venv/bin/activate" && ! -f "venv/Scripts/activate.bat" ]]; then
    echo "Detected MSYS/Bash virtual environment."
    # Source the unix-style activation script to set PATH
    source venv/bin/activate

    # Set the variable so the .bat file knows to skip its own activation steps
    export PATCHVIEW_VENV=1

	if [[ ! -f "venv/bin/pyinstaller.bat" ]]; then
    # Create a pyinstaller.bat shim in venv/bin so the Windows batch file can call 'pyinstaller'
    # This is necessary because MSYS installs 'pyinstaller' as a script, not an .exe.
    # %~dp0 refers to the directory of the bat file (venv/bin), ensuring we call the neighbor script.
    cat <<EOF > venv/bin/pyinstaller.bat
@echo off
python "%~dp0pyinstaller" %*
exit /b %errorlevel%
EOF
fi
fi

./patchview-wrapper-to-exe.bat
exit $?