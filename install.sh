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
    echo "Error: pip for python3 could not be found. Please ensure pip is installed for Python 3."
    exit 1
fi


echo "Creating Python virtual environment in '$SCRIPT_DIR/$VENV_DIR'..."
python3 -m venv "$SCRIPT_DIR/$VENV_DIR"

echo "Installing dependencies from requirements.txt into the virtual environment..."
"$SCRIPT_DIR/$VENV_DIR/bin/pip" install -r "$SCRIPT_DIR/requirements.txt"

echo "Installation complete."
echo "To activate the virtual environment, run: source $SCRIPT_DIR/$VENV_DIR/bin/activate"
echo "To run the server (after activating), use: uvicorn app.main:mcp --host 0.0.0.0 --port 8000" 