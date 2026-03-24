#!/usr/bin/env zsh
# Create symlinks from ~/.agents/skills/ and ~/.claude/skills/ to monorepo directories.
#
# Usage:
#   ./scripts/setup-skills.sh
#
# Monorepos:
#   ~/workspace/sjh_skills/skills/*     → personal skills (open-source)
#   ~/workspace/robby_skills/skills/*   → company skills (internal)
#
# Third-party skills in dotfiles are handled by stow, not this script.

set -eo pipefail

SJH_SKILLS_DIR="$HOME/workspace/sjh_skills/skills"
ROBBY_SKILLS_DIR="$HOME/workspace/robby_skills/skills"

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

# --- Personal skills (sjh_skills) ---
echo "=== Personal Skills (sjh_skills) ==="
if [[ -d "$SJH_SKILLS_DIR" ]]; then
    for skill_dir in "$SJH_SKILLS_DIR"/*/; do
        [[ ! -d "$skill_dir" ]] && continue
        skill_name=$(basename "$skill_dir")
        # scholar-agent maps to scholar-inbox link name (skill trigger name)
        link_name="$skill_name"
        [[ "$skill_name" == "scholar-agent" ]] && link_name="scholar-inbox"
        link_skill "$skill_dir" "$link_name"
    done
else
    echo "  ⚠ $SJH_SKILLS_DIR not found (clone sjh-skills first)"
fi

# --- Company skills (robby_skills) ---
echo
echo "=== Company Skills (robby_skills) ==="
if [[ -d "$ROBBY_SKILLS_DIR" ]]; then
    for skill_dir in "$ROBBY_SKILLS_DIR"/*/; do
        [[ ! -d "$skill_dir" ]] && continue
        [[ "$(basename "$skill_dir")" == ".git" ]] && continue
        link_skill "$skill_dir"
    done
else
    echo "  ⚠ $ROBBY_SKILLS_DIR not found (skip on personal Mac)"
fi

echo
echo "Done. Third-party skills managed by: cd ~/dotfiles && stow --no-folding agents && stow --no-folding claude"
