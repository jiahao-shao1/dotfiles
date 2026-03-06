#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_REPO="$DOTFILES_DIR/agents/.agents/skills"
CLAUDE_REPO="$DOTFILES_DIR/claude/.claude/skills"

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

# 2. Merge local skills into repo (keep skills that only exist locally)
if [ -d "$HOME/.agents/skills" ] && [ ! -L "$HOME/.agents" ]; then
    echo "Merging local skills into dotfiles repo..."
    for skill_dir in "$HOME/.agents/skills"/*/; do
        [ -d "$skill_dir" ] || continue
        skill=$(basename "$skill_dir")
        if [ ! -d "$AGENTS_REPO/$skill" ]; then
            echo "  + Importing local skill: $skill"
            cp -r "$skill_dir" "$AGENTS_REPO/$skill"
            ln -sf "../../../agents/.agents/skills/$skill" "$CLAUDE_REPO/$skill"
        fi
    done
fi

# 3. Backup and remove managed files
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d%H%M%S)"

# 3a. Backup tmux.conf if it's a real file
if [ -e "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$HOME/.tmux.conf" "$BACKUP_DIR/.tmux.conf"
fi

# 3b. Backup other managed files
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

# 4. Ensure ~/.claude directory exists
mkdir -p "$HOME/.claude"

# 5. Stow packages
cd "$DOTFILES_DIR"
echo "Stowing agents..."
stow --no-folding agents
echo "Stowing claude..."
stow --no-folding claude
echo "Stowing zsh..."
stow --no-folding zsh
echo "Stowing tmux..."
stow tmux

# 6. Commit and push newly imported skills
cd "$DOTFILES_DIR"
git add -A
if ! git diff --cached --quiet; then
    echo "Pushing newly imported skills to repo..."
    git commit -m "sync: import local skills from $(hostname)"
    git push
fi

# 7. Ensure .zshrc sources .zshrc.shared
if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q 'source.*\.zshrc\.shared' "$HOME/.zshrc"; then
        echo "Adding 'source ~/.zshrc.shared' to ~/.zshrc ..."
        sed -i.bak '1s/^/source "$HOME\/.zshrc.shared"\n\n/' "$HOME/.zshrc"
        rm -f "$HOME/.zshrc.bak"
    else
        echo "~/.zshrc already sources .zshrc.shared."
    fi
else
    echo 'source "$HOME/.zshrc.shared"' > "$HOME/.zshrc"
    echo "Created ~/.zshrc with source line."
fi

echo ""
echo "=== Done! ==="
echo "Verify: ls -la ~/.agents/skills/"
echo "Verify: cat ~/.claude/settings.json | head -3"
echo "Verify: readlink ~/.zshrc.shared"
echo "Verify: readlink ~/.tmux.conf"
