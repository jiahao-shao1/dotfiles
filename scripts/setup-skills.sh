#!/usr/bin/env zsh
# Create symlinks from ~/.agents/skills/ and ~/.claude/skills/ to monorepo directories.
#
# Usage:
#   ./scripts/setup-skills.sh
#
# Sources:
#   ~/workspace/robby-skills/skills/*  → company skills (internal)
#   ~/workspace/robby-cluster-connect → active cluster connection skill
#
# Note: sjh-skills are now installed via Claude Code plugin (sjh-skills@sjh-skills).
# Third-party skills are installed via: bash scripts/install-skills.sh

set -eo pipefail

ROBBY_SKILLS_DIR="$HOME/workspace/robby-skills/skills"
ROBBY_CLUSTER_CONNECT_DIR="$HOME/workspace/robby-cluster-connect"

AGENTS_DIR="$HOME/.agents/skills"
CLAUDE_DIR="$HOME/.claude/skills"

mkdir -p "$AGENTS_DIR" "$CLAUDE_DIR"

link_skill() {
    local src="$1"
    local link_name="${2:-$(basename "$src")}"

    for target_dir in "$AGENTS_DIR" "$CLAUDE_DIR"; do
        local target="$target_dir/$link_name"
        if [[ -L "$target" ]]; then
            local current=$(readlink "$target")
            if [[ "$current" == "$src" ]]; then
                echo "  ✓ $link_name (already linked)"
                return
            fi
            rm -f "$target"
        elif [[ -e "$target" ]]; then
            rm -rf "$target"
        fi
        ln -sf "$src" "$target"
    done
    echo "  ✓ $link_name → $src"
}

# --- Company skills (robby-skills) ---
echo "=== Company Skills (robby-skills) ==="
if [[ -d "$ROBBY_SKILLS_DIR" ]]; then
    for skill_dir in "$ROBBY_SKILLS_DIR"/*/; do
        [[ ! -d "$skill_dir" ]] && continue
        [[ "$(basename "$skill_dir")" == ".git" ]] && continue
        # The active cluster skill moved to its own repository. Keep the old
        # source checkout for history, but never reinstall it from this loop.
        [[ "$(basename "$skill_dir")" == "robby-cluster-connect" ]] && continue
        link_skill "$skill_dir"
    done
else
    echo "  ⚠ $ROBBY_SKILLS_DIR not found (skip on personal Mac)"
fi

echo
echo "=== Robby Cluster Connect (standalone) ==="
if [[ -d "$ROBBY_CLUSTER_CONNECT_DIR" ]]; then
    link_skill "$ROBBY_CLUSTER_CONNECT_DIR" "robby-cluster-connect"
else
    echo "  ⚠ $ROBBY_CLUSTER_CONNECT_DIR not found"
fi

echo
echo "Done. Third-party skills: bash ~/dotfiles/scripts/install-skills.sh"
