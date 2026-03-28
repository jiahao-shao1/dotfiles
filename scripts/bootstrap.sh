#!/usr/bin/env zsh
# New machine one-click setup
# Usage: bash ~/dotfiles/scripts/bootstrap.sh
#
# Company-specific setup: see scripts/bootstrap-company.sh (gitignored)

set -eo pipefail

DOTFILES_DIR="$HOME/dotfiles"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"

echo "=== [1/4] Stow dotfiles ==="
cd "$DOTFILES_DIR"
pkgs=(zsh tmux claude agents)
[[ "$(uname)" == "Darwin" ]] && pkgs+=(ghostty)
for pkg in "${pkgs[@]}"; do
  if [[ -d "$pkg" ]]; then
    stow --no-folding "$pkg" && echo "  stowed: $pkg"
  fi
done

echo ""
echo "=== [2/4] Clone sjh-skills ==="
SJH_DIR="$HOME/workspace/sjh_skills"
if [[ -d "$SJH_DIR" ]]; then
  echo "  already exists, skipping"
else
  mkdir -p "$HOME/workspace"
  git clone git@github.com:jiahao-shao1/sjh-skills.git "$SJH_DIR"
fi

echo ""
echo "=== [3/4] Setup monorepo skills ==="
bash "$SCRIPTS_DIR/setup-skills.sh"

echo ""
echo "=== [4/4] Install third-party skills ==="
bash "$SCRIPTS_DIR/install-skills.sh"

echo ""
echo "=== Optional CLI tools ==="
echo "  pipx install \"notebooklm-py[browser]\"   # NotebookLM API"
echo "  npm install -g @playwright/cli@latest  # Browser automation"
echo ""
echo "Bootstrap complete!"
