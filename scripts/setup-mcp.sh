#!/usr/bin/env zsh
# Register user-scope MCP servers for Claude Code.
#
# Usage:
#   ./scripts/setup-mcp.sh
#
# Idempotent: skips servers that are already configured.

set -eo pipefail

# Define MCP servers: "name|command|args..."
MCP_SERVERS=(
    "chrome-devtools-auto|npx|chrome-devtools-mcp@latest --autoConnect"
)

echo "=== Claude Code MCP Servers ==="

for entry in "${MCP_SERVERS[@]}"; do
    name="${entry%%|*}"
    rest="${entry#*|}"
    cmd="${rest%%|*}"
    args="${rest#*|}"

    # Check if already registered
    if claude mcp get "$name" &>/dev/null; then
        echo "  ✓ $name (already configured)"
    else
        echo "  + Adding $name..."
        eval "claude mcp add '$name' -s user -- $cmd $args"
        echo "  ✓ $name added"
    fi
done

echo
echo "Done. Run 'claude mcp list' to verify."
