#!/usr/bin/env zsh
# New machine one-click setup
# Usage: bash ~/dotfiles/scripts/bootstrap.sh
#
# Company-specific setup: see scripts/bootstrap-company.sh (gitignored)

set -eo pipefail

DOTFILES_DIR="$HOME/dotfiles"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"

echo "=== [1/6] Install dependencies ==="
bash "$DOTFILES_DIR/install.sh"

echo ""
echo "=== [2/6] Initialize Claude Code settings ==="
mkdir -p "$HOME/.claude"
if [[ ! -e "$HOME/.claude/settings.json" ]]; then
    cp "$DOTFILES_DIR/claude/settings.template.json" "$HOME/.claude/settings.json"
    echo "  Copied settings.template.json → ~/.claude/settings.json"
    echo "  Customize as needed (proxy, model, etc.)"
else
    echo "  ~/.claude/settings.json already exists, skipping"
    echo "  Template available at: $DOTFILES_DIR/claude/settings.template.json"
fi

echo ""
echo "=== [3/6] Clone sjh-skills ==="
SJH_DIR="$HOME/workspace/sjh-skills"
if [[ -d "$SJH_DIR" ]]; then
    echo "  already exists, skipping"
else
    mkdir -p "$HOME/workspace"
    git clone git@github.com:jiahao-shao1/sjh-skills.git "$SJH_DIR"
fi

echo ""
echo "=== [4/6] Setup monorepo skills ==="
bash "$SCRIPTS_DIR/setup-skills.sh"

echo ""
echo "=== [5/6] Install third-party skills ==="
bash "$SCRIPTS_DIR/install-skills.sh"

echo ""
echo "=== [6/6] Setup MCP servers ==="
bash "$SCRIPTS_DIR/setup-mcp.sh"

echo ""
echo "=== Bootstrap complete! ==="
echo ""
echo "Post-setup checklist:"
echo "  1. Verify: readlink ~/.zshrc.shared"
echo "  2. Verify: readlink ~/.tmux.conf"
echo "  3. Verify: cat ~/.claude/settings.json | head -5"
echo "  4. Customize ~/.claude/settings.json (proxy, model) if needed"
echo "  5. Optional: pipx install \"notebooklm-py[browser]\""
echo "  6. Optional: npm install -g @playwright/cli@latest"
