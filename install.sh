#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Claude Code Dotfiles Installer ==="

# 1. Install stow
if ! command -v stow &>/dev/null; then
    echo "Installing GNU Stow..."
    if [[ "$(uname)" == "Darwin" ]]; then
        brew install stow
    else
        echo "No sudo available. Installing stow from source to ~/.local ..."
        cd /tmp
        curl -sL https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz -o stow-latest.tar.gz
        tar xzf stow-latest.tar.gz
        cd stow-*/
        ./configure --prefix="$HOME/.local"
        make install
        cd "$DOTFILES_DIR"
        echo 'export PERL5LIB="$HOME/.local/share/perl/5.34.0${PERL5LIB:+:$PERL5LIB}"' >> ~/.zshrc
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
        export PERL5LIB="$HOME/.local/share/perl/5.34.0${PERL5LIB:+:$PERL5LIB}"
        export PATH="$HOME/.local/bin:$PATH"
        rm -rf /tmp/stow-latest.tar.gz /tmp/stow-*/
    fi
else
    echo "GNU Stow already installed."
fi

# 2. Backup existing configs
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d%H%M%S)"
NEED_BACKUP=false

if [ -e "$HOME/.agents" ] && [ ! -L "$HOME/.agents" ]; then
    NEED_BACKUP=true
fi
if [ -e "$HOME/.claude/settings.json" ] && [ ! -L "$HOME/.claude/settings.json" ]; then
    NEED_BACKUP=true
fi
if [ -e "$HOME/.claude/CLAUDE.md" ] && [ ! -L "$HOME/.claude/CLAUDE.md" ]; then
    NEED_BACKUP=true
fi
if [ -e "$HOME/.claude/skills" ] && [ ! -L "$HOME/.claude/skills" ]; then
    NEED_BACKUP=true
fi

if [ "$NEED_BACKUP" = true ]; then
    echo "Backing up existing configs to $BACKUP_DIR ..."
    mkdir -p "$BACKUP_DIR"
    [ -e "$HOME/.agents" ] && [ ! -L "$HOME/.agents" ] && mv "$HOME/.agents" "$BACKUP_DIR/.agents"
    [ -e "$HOME/.claude/settings.json" ] && [ ! -L "$HOME/.claude/settings.json" ] && mv "$HOME/.claude/settings.json" "$BACKUP_DIR/settings.json"
    [ -e "$HOME/.claude/CLAUDE.md" ] && [ ! -L "$HOME/.claude/CLAUDE.md" ] && mv "$HOME/.claude/CLAUDE.md" "$BACKUP_DIR/CLAUDE.md"
    [ -e "$HOME/.claude/skills" ] && [ ! -L "$HOME/.claude/skills" ] && mv "$HOME/.claude/skills" "$BACKUP_DIR/skills"
else
    echo "No existing configs to backup (or already symlinked)."
fi

# 3. Ensure ~/.claude directory exists
mkdir -p "$HOME/.claude"

# 4. Stow packages
cd "$DOTFILES_DIR"
echo "Stowing agents..."
stow agents
echo "Stowing claude..."
stow claude

echo ""
echo "=== Done! ==="
echo "Verify: ls -la ~/.agents/skills/"
echo "Verify: cat ~/.claude/settings.json | head -3"
