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

# 2. Install zsh dependencies (oh-my-zsh, plugins, themes)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh already installed."
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo "Installing zsh-syntax-highlighting..."
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
else
    echo "zsh-syntax-highlighting already installed."
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "Installing zsh-autosuggestions..."
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
    echo "zsh-autosuggestions already installed."
fi

if [ ! -d "$ZSH_CUSTOM/plugins/you-should-use" ]; then
    echo "Installing you-should-use..."
    git clone --depth=1 https://github.com/MichaelAquilina/zsh-you-should-use.git "$ZSH_CUSTOM/plugins/you-should-use"
else
    echo "you-should-use already installed."
fi

# 2b. Install Starship prompt
if ! command -v starship &>/dev/null; then
    echo "Installing Starship..."
    if [[ "$(uname)" == "Darwin" ]]; then
        brew install starship
    else
        curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
    fi
else
    echo "Starship already installed."
fi

# 2c. Configure iTerm2 to load preferences from dotfiles
if [[ "$(uname)" == "Darwin" ]] && [ -d "$DOTFILES_DIR/iterm2" ]; then
    echo "Configuring iTerm2 custom preferences..."
    defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$DOTFILES_DIR/iterm2"
    defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
    echo "iTerm2 will load preferences from $DOTFILES_DIR/iterm2"
fi

# 2d. Install Ghostty companion tools (macOS only: Fastfetch, Btop, Maple Mono font)
if [[ "$(uname)" == "Darwin" ]]; then
    echo "Installing Ghostty companion tools..."
    for tool in fastfetch btop; do
        if ! command -v "$tool" &>/dev/null; then
            echo "  Installing $tool..."
            brew install "$tool"
        else
            echo "  $tool already installed."
        fi
    done
    if ! ls "$HOME/Library/Fonts"/MapleMono-NF-CN* &>/dev/null; then
        echo "  Installing Maple Mono NF CN font..."
        brew install --cask font-maple-mono-nf-cn
    else
        echo "  Maple Mono NF CN font already installed."
    fi
    # cmux: Ghostty-based terminal with vertical tabs and notifications for AI agents
    if ! command -v cmux &>/dev/null; then
        echo "  Installing cmux..."
        brew tap manaflow-ai/cmux
        brew install --cask cmux
    else
        echo "  cmux already installed."
    fi
fi

# 3. Merge local skills into repo (keep skills that only exist locally)
if [ -d "$HOME/.agents/skills" ]; then
    echo "Merging local skills into dotfiles repo..."
    for skill_dir in "$HOME/.agents/skills"/*/; do
        [ -d "$skill_dir" ] || continue
        skill=$(basename "$skill_dir")
        # Skip if skill dir is a symlink OR has its own git repo (managed externally)
        [ -L "${skill_dir%/}" ] && continue
        [ -d "$skill_dir/.git" ] && continue
        # Skip gitignored skills
        is_gitignored "$skill" 2>/dev/null && continue
        # Skip stow-managed skills (SKILL.md is a symlink)
        [ -f "$skill_dir/SKILL.md" ] && [ ! -L "$skill_dir/SKILL.md" ] || continue
        if [ ! -d "$AGENTS_REPO/$skill" ]; then
            echo "  + Importing local skill: $skill"
            cp -r "$skill_dir" "$AGENTS_REPO/$skill"
            ln -sf "../../../agents/.agents/skills/$skill" "$CLAUDE_REPO/$skill"
        fi
    done
fi

# 4. Backup and remove managed files
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d%H%M%S)"

# 4a. Backup tmux.conf if it's a real file
if [ -e "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$HOME/.tmux.conf" "$BACKUP_DIR/.tmux.conf"
fi

# 4a2. Backup ghostty config if it's a real file (macOS only)
if [[ "$(uname)" == "Darwin" ]] && [ -e "$HOME/.config/ghostty/config" ] && [ ! -L "$HOME/.config/ghostty/config" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$HOME/.config/ghostty/config" "$BACKUP_DIR/ghostty-config"
fi

# 4a3. Backup starship config if it's a real file
if [ -e "$HOME/.config/starship.toml" ] && [ ! -L "$HOME/.config/starship.toml" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$HOME/.config/starship.toml" "$BACKUP_DIR/starship.toml"
fi

# 4b. Backup other managed files
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
    # Backup .agents skills (skip symlinks and git repos — they're managed externally)
    if [ -e "$HOME/.agents" ] && [ ! -L "$HOME/.agents" ]; then
        mkdir -p "$BACKUP_DIR/.agents/skills"
        for skill_dir in "$HOME/.agents/skills"/*/; do
            [ -d "$skill_dir" ] || continue
            [ -L "${skill_dir%/}" ] && continue
            [ -d "$skill_dir/.git" ] && continue
            mv "$skill_dir" "$BACKUP_DIR/.agents/skills/"
        done
    fi
    [ -e "$HOME/.claude/settings.json" ] && [ ! -L "$HOME/.claude/settings.json" ] && mv "$HOME/.claude/settings.json" "$BACKUP_DIR/settings.json"
    [ -e "$HOME/.claude/CLAUDE.md" ] && [ ! -L "$HOME/.claude/CLAUDE.md" ] && mv "$HOME/.claude/CLAUDE.md" "$BACKUP_DIR/CLAUDE.md"
    # Backup .claude/skills (skip symlinks and git repos)
    if [ -e "$HOME/.claude/skills" ] && [ ! -L "$HOME/.claude/skills" ]; then
        mkdir -p "$BACKUP_DIR/skills"
        for skill in "$HOME/.claude/skills"/*/; do
            [ -d "$skill" ] || continue
            [ -L "${skill%/}" ] && continue
            [ -d "$skill/.git" ] && continue
            mv "$skill" "$BACKUP_DIR/skills/"
        done
    fi
else
    echo "No existing configs to backup (or already symlinked)."
fi

# 5. Ensure ~/.claude directory exists
mkdir -p "$HOME/.claude"

# 5b. Initialize submodules
echo "Initializing submodules..."
cd "$DOTFILES_DIR"
git submodule update --init --recursive

# 6. Detect machine type and build stow ignore list
STOW_IGNORE=""
MACHINE_HOST="$(hostname)"
echo "Machine: $MACHINE_HOST"

# 7. Stow packages
cd "$DOTFILES_DIR"
echo "Stowing agents..."
stow -R --no-folding $STOW_IGNORE agents
echo "Stowing claude..."
stow -R --no-folding $STOW_IGNORE claude
echo "Stowing zsh..."
stow -R --no-folding zsh
echo "Stowing starship..."
stow -R --no-folding starship
echo "Stowing tmux..."
stow -R tmux
if [[ "$(uname)" == "Darwin" ]]; then
    echo "Stowing ghostty..."
    mkdir -p "$HOME/.config/ghostty"
    stow -R --no-folding ghostty
fi

# 7. Commit and push newly imported skills
cd "$DOTFILES_DIR"
git add -A
if ! git diff --cached --quiet; then
    echo "Pushing newly imported skills to repo..."
    git commit -m "sync: import local skills from $(hostname)"
    BRANCH="$(git symbolic-ref --short HEAD)"
    case "$(hostname)" in
        MacBook-Pro*)  PUSH_REMOTE="internal-git" ;;
        *)             PUSH_REMOTE="origin" ;;
    esac
    git remote get-url "$PUSH_REMOTE" &>/dev/null && git push "$PUSH_REMOTE" "$BRANCH" 2>/dev/null
fi

# 8. Ensure .zshrc sources .zshrc.shared
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
