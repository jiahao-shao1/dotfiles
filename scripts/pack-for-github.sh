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
SKILLS_DIR="$HOME/workspace/my_skills"
OUTPUT_DIR="${1:-$HOME}"
BUNDLE_DIR=$(mktemp -d)

echo "Packing repos for GitHub sync..."
echo

# --- Dotfiles ---
echo "  dotfiles..."
cd "$DOTFILES_DIR"
git bundle create "$BUNDLE_DIR/dotfiles.bundle" --all 2>/dev/null
echo "    ✓ $(du -h "$BUNDLE_DIR/dotfiles.bundle" | cut -f1)"

# --- Skills ---
if [[ ! -d "$SKILLS_DIR" ]]; then
    echo "Error: $SKILLS_DIR not found" >&2
    exit 1
fi

for skill_dir in "$SKILLS_DIR"/*/; do
    skill_name=$(basename "$skill_dir")
    if [[ ! -d "$skill_dir/.git" ]]; then
        echo "  $skill_name — skipping (not a git repo)"
        continue
    fi
    echo "  $skill_name..."
    cd "$skill_dir"
    git bundle create "$BUNDLE_DIR/$skill_name.bundle" --all 2>/dev/null
    echo "    ✓ $(du -h "$BUNDLE_DIR/$skill_name.bundle" | cut -f1)"
done

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
