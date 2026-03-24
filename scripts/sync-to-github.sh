#!/usr/bin/env zsh
# Unpack git bundles and push all repos to GitHub.
# Run this on your PERSONAL Mac only.
#
# Usage:
#   ./scripts/sync-to-github.sh ~/Downloads/github-sync.zip
#
# First run: clones from bundles, sets up GitHub remotes, pushes.
# Subsequent runs: pulls incremental changes from bundles, pushes to GitHub.

set -eo pipefail

GITHUB_USER="jiahao-shao1"
SKILLS_DIR="$HOME/workspace/my_skills"
DOTFILES_DIR="$HOME/dotfiles"

ZIP_PATH="${1:?Usage: sync-to-github.sh <path-to-github-sync.zip>}"

if [[ ! -f "$ZIP_PATH" ]]; then
    echo "Error: $ZIP_PATH not found" >&2
    exit 1
fi

# Unzip bundles to temp dir
BUNDLE_DIR=$(mktemp -d)
unzip -o "$ZIP_PATH" -d "$BUNDLE_DIR" >/dev/null
echo "Unpacked bundles to $BUNDLE_DIR"
echo

# --- Sync a skill repo ---
sync_skill() {
    local name="$1"
    local bundle="$BUNDLE_DIR/$name.bundle"
    local dir="$SKILLS_DIR/$name"
    local github_repo="$name"

    # scholar-inbox bundle → scholar-agent GitHub repo
    if [[ "$name" == "scholar-inbox" ]]; then
        github_repo="scholar-agent"
    fi

    local github_url="git@github.com:${GITHUB_USER}/${github_repo}.git"

    if [[ ! -f "$bundle" ]]; then
        echo "  $name — no bundle found, skipping"
        return
    fi

    echo "  $name → $github_repo"

    if [[ -d "$dir/.git" ]]; then
        # Existing repo: pull from bundle
        cd "$dir"
        git fetch "$bundle" 'refs/heads/*:refs/remotes/bundle/*' 2>/dev/null
        git merge bundle/main --ff-only 2>/dev/null || true
    else
        # New repo: clone from bundle
        mkdir -p "$SKILLS_DIR"
        git clone "$bundle" "$dir" 2>/dev/null
        cd "$dir"
    fi

    # Ensure github remote exists
    if ! git remote get-url github &>/dev/null; then
        git remote add github "$github_url"
    fi

    git push github main 2>&1 | sed 's/^/    /'
    echo "    ✓ pushed"
}

# --- Sync dotfiles ---
sync_dotfiles() {
    local bundle="$BUNDLE_DIR/dotfiles.bundle"

    if [[ ! -f "$bundle" ]]; then
        echo "  dotfiles — no bundle found, skipping"
        return
    fi

    echo "  dotfiles"

    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        cd "$DOTFILES_DIR"
        git fetch "$bundle" 'refs/heads/*:refs/remotes/bundle/*' 2>/dev/null
        git merge bundle/main --ff-only 2>/dev/null || true
    else
        git clone "$bundle" "$DOTFILES_DIR" 2>/dev/null
        cd "$DOTFILES_DIR"
    fi

    # Switch submodule URLs to GitHub
    if [[ -x "$DOTFILES_DIR/scripts/switch-submodule-urls.sh" ]]; then
        "$DOTFILES_DIR/scripts/switch-submodule-urls.sh" github 2>&1 | sed 's/^/    /'
    fi

    # Update submodule pointers
    git submodule update --init --recursive 2>/dev/null || true

    # Ensure github remote
    if ! git remote get-url github &>/dev/null; then
        git remote add github "git@github.com:${GITHUB_USER}/dotfiles.git"
    fi

    # Commit URL switch if there are changes
    if ! git diff --quiet .gitmodules 2>/dev/null; then
        git add .gitmodules
        git commit -m "chore: switch submodule URLs to GitHub for push" 2>/dev/null || true
    fi

    git push github main 2>&1 | sed 's/^/    /'
    echo "    ✓ pushed"

    # Switch back to internal-git URLs (so next bundle pull works cleanly)
    if [[ -x "$DOTFILES_DIR/scripts/switch-submodule-urls.sh" ]]; then
        "$DOTFILES_DIR/scripts/switch-submodule-urls.sh" internal-git >/dev/null 2>&1
        if ! git diff --quiet .gitmodules 2>/dev/null; then
            git add .gitmodules
            git commit -m "chore: switch submodule URLs back to internal-git" 2>/dev/null || true
        fi
    fi
}

# --- Execute ---
echo "=== Skills ==="
for bundle in "$BUNDLE_DIR"/*.bundle; do
    name=$(basename "$bundle" .bundle)
    [[ "$name" == "dotfiles" ]] && continue
    sync_skill "$name"
done

echo
echo "=== Dotfiles ==="
sync_dotfiles

# Cleanup
rm -rf "$BUNDLE_DIR"

echo
echo "All repos synced to GitHub."
