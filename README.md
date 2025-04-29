# jetson-mcp

A MCP (Model Context Protocol) server for using natural language to monitor and remotely control a Nvidia Jetson board from clients on the same network.

This project uses the [FastMCP](https://github.com/jlowin/fastmcp) library to create the server.

## Features

*   Provides MCP tools accessible by network clients using the SSE (Server-Sent Events) transport.
*   **`get_jetson_hw_info`**: Reads `/etc/nv_boot_control.conf` to identify module/carrier board info.
*   **`get_jetson_sw_info`**: Reads `/etc/nv_tegra_release` (for Jetpack version) and `/proc/version` (for Linux kernel version).
*   Includes scripts for easy installation and systemd service setup.

## Setup and Installation (on the Jetson)

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Zalmotek/jetson-mcp
    cd jetson-mcp
    ```
2.  **Run the installation script:**
    This script creates a Python virtual environment (`venv/`) and installs dependencies from `requirements.txt`.
    ```bash
    chmod +x install.sh
    ./install.sh
    ```

## Running the Server (on the Jetson)

The recommended way to run the server is as a background service managed by systemd.

1.  **(Optional) Find Jetson IP/Hostname:**
    You'll need the Jetson's IP address or hostname to connect from other devices. Use commands like `ip addr` or `hostname -I`.

2.  **Run the service setup script:**
    This script creates and enables a systemd service file (`/etc/systemd/system/jetson-mcp.service`) configured to run the server as the user who invoked the script, listening on port 8000.
    ```bash
    chmod +x setup_service.sh
    sudo ./setup_service.sh
    ```
3.  **Start the service:**
    ```bash
    sudo systemctl start jetson-mcp.service
    ```
4.  **Verify Service:**
    ```bash
    sudo systemctl status jetson-mcp.service
    # Check logs for errors
    sudo journalctl -u jetson-mcp.service -f
    ```
5.  **Firewall**: Ensure your Jetson's firewall (if active, e.g., `ufw`) allows incoming connections on port 8000 (or your chosen port). Example for `ufw`:
    ```bash
    sudo ufw allow 8000/tcp
    ```

### Running Manually (for testing)

You can also run the server manually in the foreground using Python directly:

```bash
source venv/bin/activate
# The script itself now calls mcp.run() with SSE, host, and port settings
python app/main.py
```

## Connecting from a Remote Client

Once the server is running on the Jetson and accessible on the network (port 8000 allowed through firewall):

1.  **Identify the Server Address**: Find the Jetson's IP address (e.g., `192.168.1.105`) or its hostname (e.g., `jetson-nano.local`) on your LAN.
2.  **Configure Your Client**: In your MCP client application (which could be a custom script, a UI like MCP Inspector, or potentially Cursor/Claude if they support network endpoints), configure it to connect to the MCP server at its network address.
    *   The specific connection method depends on the client, but it will likely involve specifying a URL for the SSE endpoint:
        *   `http://<jetson_ip_or_hostname>:8000/sse` (Common pattern for SSE)


*Note: Cursor's `mcp.json` file is primarily designed for launching local servers via `stdio` transport. Connecting Cursor to this networked SSE server might require different configuration steps or might not be directly supported without a proxy.* Consult your specific client's documentation for how to connect to a network MCP SSE endpoint.
