#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

SERVICE_NAME="jetson-mcp"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# --- Configuration ---
# Get the absolute path of the script's directory (project root)
PROJECT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Attempt to get the user who invoked sudo, otherwise fallback to current user
# This is important because $USER inside sudo might be 'root'
SERVICE_USER="${SUDO_USER:-$(whoami)}"
if [ -z "$SERVICE_USER" ] || [ "$SERVICE_USER" == "root" ]; then
    echo "Error: Could not determine the non-root user to run the service."
    echo "Please run this script using 'sudo -u <your_user> ./setup_service.sh' or set SUDO_USER manually."
    # As a last resort maybe try the owner of the script dir?
    SERVICE_USER=$(stat -c '%U' "$PROJECT_DIR")
    if [ -z "$SERVICE_USER" ] || [ "$SERVICE_USER" == "root" ]; then
        echo "Error: Could not determine service user automatically. Exiting."
        exit 1
    fi
    echo "Warning: Using directory owner '$SERVICE_USER' as the service user."
fi

# Get the primary group of the service user
SERVICE_GROUP=$(id -gn "$SERVICE_USER")
if [ -z "$SERVICE_GROUP" ]; then
     echo "Error: Could not determine the primary group for user '$SERVICE_USER'. Exiting."
     exit 1
fi


# --- Check Permissions ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: This script must be run as root (using sudo)." >&2
  exit 1
fi

# --- Check if venv exists ---
VENV_PATH="${PROJECT_DIR}/venv"
if [ ! -d "$VENV_PATH" ]; then
    echo "Error: Virtual environment not found at '$VENV_PATH'."
    echo "Please run ./install.sh first."
    exit 1
fi
UVICORN_PATH="${VENV_PATH}/bin/uvicorn"
if [ ! -x "$UVICORN_PATH" ]; then
    echo "Error: uvicorn executable not found or not executable at '$UVICORN_PATH'."
    echo "Ensure ./install.sh completed successfully."
    exit 1
fi

# --- Create systemd Service File ---
echo "Creating systemd service file at ${SERVICE_FILE}..."

# Use cat with a heredoc to write the service file content
cat << EOF > "${SERVICE_FILE}"
[Unit]
Description=Jetson MCP Server
After=network.target

[Service]
User=${SERVICE_USER}
Group=${SERVICE_GROUP}
WorkingDirectory=${PROJECT_DIR}
# Execute the python script directly; it handles its own launch via mcp.run()
ExecStart=${PROJECT_DIR}/venv/bin/python ${PROJECT_DIR}/app/main.py
Restart=on-failure
RestartSec=5s
# Ensure logs go to journald
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "Service file created."

# --- Reload Systemd and Enable Service ---
echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling ${SERVICE_NAME} service to start on boot..."
systemctl enable "${SERVICE_NAME}.service"

echo ""
echo "Setup complete!"
echo "You can now manage the service using:"
echo "  sudo systemctl start ${SERVICE_NAME}"
echo "  sudo systemctl stop ${SERVICE_NAME}"
echo "  sudo systemctl restart ${SERVICE_NAME}"
echo "  sudo systemctl status ${SERVICE_NAME}"
echo "  sudo journalctl -u ${SERVICE_NAME} -f  (to view logs)" 