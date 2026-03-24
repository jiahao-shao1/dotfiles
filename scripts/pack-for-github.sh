#!/usr/bin/env zsh
# Pack dotfiles + all skill repos into git bundles for transfer to personal Mac.
#
# Usage:
#   ./scripts/pack-for-github.sh [output_dir]
#
# Output: ~/github-sync.zip containing .bundle files for each repo.
# Transfer via Overleaf or any file-sharing method.
# On personal Mac, run: ./scripts/sync-to-github.sh ~/Downloads/github-sync.zip

set -eo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SJH_SKILLS_DIR="$HOME/workspace/sjh_skills"
OUTPUT_DIR="${1:-$HOME}"
BUNDLE_DIR=$(mktemp -d)

echo "Packing repos for GitHub sync..."
echo

# --- Dotfiles ---
echo "  dotfiles..."
cd "$DOTFILES_DIR"
git bundle create "$BUNDLE_DIR/dotfiles.bundle" --all 2>/dev/null
echo "    ✓ $(du -h "$BUNDLE_DIR/dotfiles.bundle" | cut -f1)"

# --- sjh_skills monorepo ---
if [[ -d "$SJH_SKILLS_DIR/.git" ]]; then
    echo "  sjh_skills..."
    cd "$SJH_SKILLS_DIR"
    git bundle create "$BUNDLE_DIR/sjh_skills.bundle" --all 2>/dev/null
    echo "    ✓ $(du -h "$BUNDLE_DIR/sjh_skills.bundle" | cut -f1)"
else
    echo "  sjh_skills — not found or not a git repo" >&2
fi

# --- Include sync script ---
SYNC_SCRIPT="$DOTFILES_DIR/scripts/sync-to-github.sh"
if [[ -f "$SYNC_SCRIPT" ]]; then
    cp "$SYNC_SCRIPT" "$BUNDLE_DIR/"
    echo "  sync-to-github.sh included"
fi

# --- Zip ---
ZIP_PATH="$OUTPUT_DIR/github-sync.zip"
cd "$BUNDLE_DIR"
zip -j "$ZIP_PATH" * >/dev/null
rm -rf "$BUNDLE_DIR"

echo
echo "Done: $ZIP_PATH ($(du -h "$ZIP_PATH" | cut -f1))"
echo "Transfer this to your personal Mac, then run:"
echo "  ./scripts/sync-to-github.sh ~/Downloads/github-sync.zip"
