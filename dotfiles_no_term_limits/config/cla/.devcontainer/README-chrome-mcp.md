# Chrome DevTools MCP Server Configuration

This devcontainer includes a script to easily configure the Chrome DevTools MCP server for Claude Code.

## Quick Start

1. **Start Chrome with remote debugging on your host:**
   ```bash
   # On macOS/Linux
   google-chrome --remote-debugging-port=9222 --remote-debugging-address=0.0.0.0

   # On Windows
   chrome.exe --remote-debugging-port=9222 --remote-debugging-address=0.0.0.0
   ```

2. **Inside the container, configure the MCP server:**
   ```bash
   configure-chrome-mcp.sh
   ```

3. **Restart Claude Code or reload the workspace** to activate the MCP server.

## Script Commands

- `configure-chrome-mcp.sh` - Configure Chrome DevTools MCP server (default)
- `configure-chrome-mcp.sh test` - Test Chrome connection without configuring
- `configure-chrome-mcp.sh show` - Show current Chrome MCP configuration
- `configure-chrome-mcp.sh remove` - Remove Chrome MCP configuration
- `configure-chrome-mcp.sh help` - Show help message

## Environment Variables

- `CHROME_PORT` - Chrome remote debugging port (default: 9222)

## How It Works

1. The script automatically detects the Docker host IP address
2. Updates your Claude config at `/home/node/.claude/.claude.json`
3. Configures the Chrome DevTools MCP server with the correct browser URL
4. Tests the connection to ensure Chrome is accessible

## Troubleshooting

### Chrome connection fails
- Ensure Chrome is started with the correct flags
- Check that port 9222 is not blocked by firewall
- Try manually testing: `curl http://192.168.65.254:9222/json/version`

### MCP server doesn't appear in Claude
- Restart Claude Code completely
- Check the configuration: `configure-chrome-mcp.sh show`
- Verify the JSON syntax is valid: `jq . /home/node/.claude/.claude.json`

## Configuration File Locations

The Chrome MCP server configuration is stored in:
- **Global Config**: `/home/node/.claude/.claude.json`
- **Section**: `projects["/workspace"].mcpServers["chrome-devtools"]`

This configuration is isolated per project using Docker volumes.

## Claude Config Isolation

This devcontainer uses volume mounts to isolate Claude configurations:

- **Global Claude Config** (`/home/node/.claude`) - Isolated per project
- **Workspace Claude Settings** (`/workspace/.claude`) - Isolated per project
- **Project Files** (`/workspace` except `.claude`) - Shared with host

Each project gets its own volumes:
- `claude-code-config-${PROJECT_BASENAME}` (global config)
- `claude-code-workspace-config-${PROJECT_BASENAME}` (workspace settings)

## Existing Claude Settings

If your project already has a `.claude` directory on the host, the volume mount will "shadow" it, making it inaccessible from the container but preserving it on the host. The container will start with a fresh, isolated workspace Claude configuration.