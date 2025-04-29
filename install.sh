#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define the virtual environment directory name
VENV_DIR="venv"

# Get the absolute path of the script's directory
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Check if Python 3 is available
if ! command -v python3 &> /dev/null
then
    echo "Error: python3 could not be found. Please install Python 3."
    exit 1
fi

# Check if pip is available for Python 3
if ! python3 -m pip --version &> /dev/null
then
    echo "-------------------------------------------------------------------"
    echo "Error: pip for python3 could not be found."
    echo "pip is required to install dependencies into the virtual environment."
    echo ""
    echo "Please install pip for Python 3 using your system package manager."
    echo "For Debian/Ubuntu-based systems (like Jetson L4T), run:"
    echo "  sudo apt update"
    echo "  sudo apt install python3-pip"
    echo ""
    echo "After installing pip, re-run this script ('./install.sh')."
    echo "-------------------------------------------------------------------"
    exit 1
fi

# Check if the venv module is available
echo "Checking for Python 3 venv module..."
if ! python3 -m venv --help &> /dev/null
then
    echo "-------------------------------------------------------------------"
    echo "Error: Python 3 venv module not found."
    echo "The venv module is required to create isolated Python environments."
    echo ""
    echo "Please install the venv module for Python 3 using your system package manager."
    echo "For Debian/Ubuntu-based systems (like Jetson L4T), run:"
    echo "  sudo apt update"
    echo "  sudo apt install python3-venv"
    echo ""
    echo "After installing the venv module, re-run this script ('./install.sh')."
    echo "-------------------------------------------------------------------"
    exit 1
else
    echo "Python 3 venv module found."
fi

echo "Creating Python virtual environment in '$SCRIPT_DIR/$VENV_DIR'..."
python3 -m venv "$SCRIPT_DIR/$VENV_DIR"

# Upgrade pip within the virtual environment
echo "Upgrading pip within the virtual environment..."
"$SCRIPT_DIR/$VENV_DIR/bin/python" -m pip install --upgrade pip

echo "Installing dependencies from requirements.txt into the virtual environment..."
"$SCRIPT_DIR/$VENV_DIR/bin/pip" install -r "$SCRIPT_DIR/requirements.txt"

echo "Installation complete."
echo "To activate the virtual environment, run: source $SCRIPT_DIR/$VENV_DIR/bin/activate"
echo "To run the server (after activating), use: python $SCRIPT_DIR/app/main.py" 