#!/usr/bin/env zsh
# Switch all submodule URLs between internal-git and GitHub.
#
# Usage:
#   ./scripts/switch-submodule-urls.sh github   # internal-git → GitHub
#   ./scripts/switch-submodule-urls.sh internal-git   # GitHub → internal-git
#
# Repo name mapping (internal-git → GitHub) when they differ.
# Add new entries to the function below.

set -eo pipefail

GITHUB_USER="jiahao-shao1"
GIT_USER="shaojiahao.sjh"

# Maps internal-git repo name → GitHub repo name (only when different)
internal-git_to_github() {
    case "$1" in
        # Add mappings here when repo names differ:
        # some-internal-git-name) echo "some-github-name" ;;
        *) echo "$1" ;;
    esac
}

# Reverse: GitHub repo name → internal-git repo name
github_to_internal-git() {
    case "$1" in
        # Add reverse mappings:
        # some-github-name) echo "some-internal-git-name" ;;
        *) echo "$1" ;;
    esac
}

direction="${1:-}"

if [[ "$direction" != "github" && "$direction" != "internal-git" ]]; then
    echo "Usage: $0 <github|internal-git>"
    echo "  github  — switch all submodule URLs to GitHub"
    echo "  internal-git — switch all submodule URLs to internal-git"
    exit 1
fi

cd "$(git -C "$(dirname "$0")/.." rev-parse --show-toplevel)"

echo "Switching submodule URLs to $direction..."
echo

git submodule foreach --quiet 'echo $name' | while read -r name; do
    current_url=$(git config --file .gitmodules "submodule.$name.url")

    if [[ "$direction" == "github" ]]; then
        if [[ "$current_url" == *"internal-git-host"* ]]; then
            internal-git_repo=$(basename "$current_url" .git)
            github_repo=$(internal-git_to_github "$internal-git_repo")
            new_url="git@github.com:${GITHUB_USER}/${github_repo}.git"
            echo "  $name"
            echo "    $current_url"
            echo "    → $new_url"
            git submodule set-url "$name" "$new_url"
        else
            echo "  $name — already GitHub, skipping"
        fi
    else
        if [[ "$current_url" == *"github.com"* ]]; then
            github_repo=$(basename "$current_url" .git)
            internal-git_repo=$(github_to_internal-git "$github_repo")
            new_url="git@internal-git-host:${GIT_USER}/${internal-git_repo}.git"
            echo "  $name"
            echo "    $current_url"
            echo "    → $new_url"
            git submodule set-url "$name" "$new_url"
        else
            echo "  $name — already internal-git, skipping"
        fi
    fi
done

echo
echo "Done. Review with 'git diff .gitmodules', then commit."
