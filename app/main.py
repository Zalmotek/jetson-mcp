import subprocess
import shlex
import logging

# Use FastMCP again
from mcp.server import FastMCP

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastMCP server
# The name is used for identification in clients
mcp = FastMCP("Jetson MCP Server (FastMCP)")

# --- Tool Implementations (using decorators) ---

@mcp.tool()
async def get_jetson_hw_info() -> str:
    """This tool provides information about the Jetson board hardware capabilities (module/carrier board info)."""
    command = "cat /etc/nv_boot_control.conf"
    logger.info(f"Executing command: {command}")
    try:
        result = subprocess.run(
            command,
            shell=True,
            check=True,
            capture_output=True,
            text=True
        )
        logger.info(f"Command successful. Output length: {len(result.stdout)}")
        return result.stdout.strip()
    except FileNotFoundError:
        logger.error(f"Error: File /etc/nv_boot_control.conf not found.")
        return "Error: /etc/nv_boot_control.conf not found."
    except subprocess.CalledProcessError as e:
        logger.error(f"Error executing command \'{command}\': {e}")
        logger.error(f"Stderr: {e.stderr.strip()}")
        return f"Error executing command: {e.stderr.strip() or e}"
    except Exception as e:
        logger.exception(f"An unexpected error occurred while running command: {command}")
        return f"An unexpected error occurred: {e}"

@mcp.tool()
async def get_jetson_sw_info() -> dict:
    """This tool provides information about the Jetson board software capabilities (Linux kernel version and Jetpack version)."""
    logger.info("Executing get_jetson_sw_info tool...")
    
    sw_info = {
        "jetpack_release": "N/A",
        "linux_version": "N/A",
        "errors": []
    }

    commands = {
        "jetpack_release": "cat /etc/nv_tegra_release",
        "linux_version": "cat /proc/version"
    }

    for key, command in commands.items():
        logger.info(f"Executing command: {command}")
        try:
            result = subprocess.run(
                command,
                shell=True, # Use shell=True carefully
                check=True,
                capture_output=True,
                text=True
            )
            sw_info[key] = result.stdout.strip()
            logger.info(f"Command '{command}' successful.")
        except FileNotFoundError:
            error_msg = f"File not found for command: {command}"
            logger.error(error_msg)
            sw_info["errors"].append(error_msg)
            sw_info[key] = "Error: File not found"
        except subprocess.CalledProcessError as e:
            error_msg = f"Error executing command '{command}': {e.stderr.strip() or e}"
            logger.error(error_msg)
            sw_info["errors"].append(error_msg)
            sw_info[key] = f"Error: {e.stderr.strip() or e}"
        except Exception as e:
            error_msg = f"An unexpected error occurred while running command '{command}': {e}"
            logger.exception(error_msg)
            sw_info["errors"].append(error_msg)
            sw_info[key] = f"Error: Unexpected error"

    # Remove errors key if empty
    if not sw_info["errors"]:
        del sw_info["errors"]

    return sw_info

# --- Resource Implementations (using decorators) ---

@mcp.resource("jetson://info")
async def get_jetson_info() -> dict:
    """Provides basic information about the Jetson MCP server."""
    logger.info("Executing get_jetson_info resource...")
    # Use the name string directly instead of relying on mcp.title
    server_name = "Jetson MCP Server (FastMCP)"
    # Hardcode the list of capabilities since mcp.get_tools() doesn't exist
    capabilities_list = ["get_jetson_hw_info", "get_jetson_sw_info"]
    return {
        "server_name": server_name,
        "version": "0.3.0",
        "description": "MCP Server for monitoring and controlling a Jetson board (using FastMCP/SSE).",
        "capabilities": capabilities_list
    }

# Note: We do not need Starlette setup.
# The 'mcp.run()' method below should handle launching.

if __name__ == "__main__":
    logger.info("Starting Jetson MCP Server via mcp.run() in SSE mode...")
    try:
        # Pass transport, host, and port directly to the run method
        mcp.run(transport='sse', host='0.0.0.0', port=8000, log_level='info') # Added log_level
    except TypeError as e:
        logger.error(f"Failed to start server with host/port/log_level arguments: {e}")
        logger.info("Attempting to start server with transport='sse' only (might bind to localhost:8000)...")
        try:
            # Fallback if host/port aren't accepted directly
             mcp.run(transport='sse')
        except Exception as e2:
            logger.exception(f"Failed to start server even with fallback: {e2}")
