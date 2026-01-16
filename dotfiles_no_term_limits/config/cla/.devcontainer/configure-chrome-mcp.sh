#!/bin/bash

# Script to configure Chrome DevTools MCP server in Claude config
# Run this inside the container after starting Chrome with remote debugging

set -euo pipefail

# Suppress locale warnings
export LC_ALL=C

CLAUDE_CONFIG_FILE="/home/node/.claude/.claude.json"
CHROME_PORT="${CHROME_PORT:-9222}"
MCP_SERVER_NAME="chrome-devtools"

# Function to get Docker host IP
get_docker_host_ip() {
    # Use dig to get clean IPv4 address for host.docker.internal
    local host_ip=$(dig host.docker.internal A +short 2>/dev/null | head -1)

    if [[ -n "$host_ip" ]]; then
        echo "Found Docker host IP: $host_ip" >&2
        echo "$host_ip"
    else
        echo "❌ Failed to resolve host.docker.internal IPv4 address" >&2
        echo "   Make sure Docker Desktop is running properly" >&2
        exit 1
    fi
}

# Function to create Claude config directory if it doesn't exist
ensure_claude_config() {
    local config_dir=$(dirname "$CLAUDE_CONFIG_FILE")
    if [[ ! -d "$config_dir" ]]; then
        echo "Creating Claude config directory: $config_dir"
        mkdir -p "$config_dir"
    fi
}

# Function to initialize empty Claude config if it doesn't exist
init_claude_config() {
    if [[ ! -f "$CLAUDE_CONFIG_FILE" ]]; then
        echo "Creating new Claude config file: $CLAUDE_CONFIG_FILE"
        cat > "$CLAUDE_CONFIG_FILE" <<EOF
{
  "projects": {}
}
EOF
    fi
}

# Function to add/update Chrome DevTools MCP server configuration
configure_chrome_mcp() {
    local host_ip="$1"
    local browser_url="http://${host_ip}:${CHROME_PORT}"

    echo "Configuring Chrome DevTools MCP server..."
    echo "Browser URL: $browser_url"

    # Use jq to update the configuration
    local temp_file=$(mktemp)
    jq --arg workspace "/workspace" \
       --arg server_name "$MCP_SERVER_NAME" \
       --arg browser_url "$browser_url" \
       '.projects[$workspace].mcpServers[$server_name] = {
         "type": "stdio",
         "command": "npx",
         "args": [
           "chrome-devtools-mcp@latest",
           ("--browser-url=" + $browser_url)
         ],
         "env": {}
       }' "$CLAUDE_CONFIG_FILE" > "$temp_file"

    mv "$temp_file" "$CLAUDE_CONFIG_FILE"
    echo "Chrome DevTools MCP server configured successfully!"
}

# Function to test Chrome connection
test_chrome_connection() {
    local host_ip="$1"
    local chrome_url="http://${host_ip}:${CHROME_PORT}/json/version"

    echo "Testing Chrome connection at: $chrome_url"
    if curl -s --connect-timeout 5 "$chrome_url" >/dev/null; then
        echo "✅ Chrome is accessible at $chrome_url"
        return 0
    else
        echo "❌ Chrome is not accessible at $chrome_url"
        echo "   Make sure Chrome is running with: --remote-debugging-port=$CHROME_PORT"
        return 1
    fi
}

# Function to show current configuration
show_config() {
    if [[ -f "$CLAUDE_CONFIG_FILE" ]]; then
        echo "Current Chrome MCP configuration:"
        jq -r ".projects[\"/workspace\"].mcpServers[\"$MCP_SERVER_NAME\"] // \"Not configured\"" "$CLAUDE_CONFIG_FILE"
    else
        echo "Claude config file not found: $CLAUDE_CONFIG_FILE"
    fi
}

# Main execution
main() {
    case "${1:-configure}" in
        "configure")
            ensure_claude_config
            init_claude_config

            local host_ip=$(get_docker_host_ip)
            configure_chrome_mcp "$host_ip"

            echo ""
            if test_chrome_connection "$host_ip"; then
                echo ""
                echo "🎉 Setup complete! Chrome DevTools MCP server is ready to use."
                echo "   Restart Claude Code or reload the workspace to activate the MCP server."
            else
                echo ""
                echo "⚠️  Configuration saved, but Chrome connection test failed."
                echo "   Start Chrome on the host with:"
                echo "   chrome --remote-debugging-port=$CHROME_PORT --remote-debugging-address=0.0.0.0"
            fi
            ;;
        "test")
            local host_ip=$(get_docker_host_ip)
            test_chrome_connection "$host_ip"
            ;;
        "show")
            show_config
            ;;
        "remove")
            if [[ -f "$CLAUDE_CONFIG_FILE" ]]; then
                local temp_file=$(mktemp)
                jq "del(.projects[\"/workspace\"].mcpServers[\"$MCP_SERVER_NAME\"])" "$CLAUDE_CONFIG_FILE" > "$temp_file"
                mv "$temp_file" "$CLAUDE_CONFIG_FILE"
                echo "Chrome DevTools MCP server configuration removed."
            else
                echo "Claude config file not found."
            fi
            ;;
        "help"|"-h"|"--help")
            cat <<EOF
Usage: $(basename "$0") [COMMAND]

Commands:
  configure  Configure Chrome DevTools MCP server (default)
  test       Test Chrome connection without configuring
  show       Show current Chrome MCP configuration
  remove     Remove Chrome MCP configuration
  help       Show this help message

Environment Variables:
  CHROME_PORT  Chrome remote debugging port (default: 9222)

Example Chrome startup command:
  chrome --remote-debugging-port=9222 --remote-debugging-address=0.0.0.0
EOF
            ;;
        *)
            echo "Unknown command: $1"
            echo "Run '$(basename "$0") help' for usage information."
            exit 1
            ;;
    esac
}

main "$@"