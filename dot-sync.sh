#!/bin/bash
# dot-sync: Sync dotfiles repo with local changes
# Usage:
#   dot-sync           — detect new/removed skills, commit, push
#   dot-sync status    — show what would be synced (dry run)
set -e

DOTFILES_DIR="$HOME/dotfiles"
AGENTS_REPO="$DOTFILES_DIR/agents/.agents/skills"
CLAUDE_REPO="$DOTFILES_DIR/claude/.claude/skills"
AGENTS_LOCAL="$HOME/.agents/skills"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

is_gitignored() {
    cd "$DOTFILES_DIR" && git check-ignore -q "agents/.agents/skills/$1" 2>/dev/null
}

# Remove private config ignores from skill .gitignore (dotfiles repo is private, no need to ignore)
unignore_private_configs() {
    local gitignore="$1/.gitignore"
    [ -f "$gitignore" ] && sed -i '' '/^CONFIG\.private\.md$/d' "$gitignore"
}

sync_skills() {
    local dry_run=$1
    local changes=0

    # 1. Find new local skills (real dirs, not stow symlink files)
    for skill_dir in "$AGENTS_LOCAL"/*/; do
        skill=$(basename "$skill_dir")
        # Check if the SKILL.md is a real file (not a stow symlink)
        if [ -f "$skill_dir/SKILL.md" ] && [ ! -L "$skill_dir/SKILL.md" ]; then
            # Skip gitignored skills (e.g. company-internal)
            if is_gitignored "$skill"; then
                continue
            fi
            if [ ! -d "$AGENTS_REPO/$skill" ]; then
                echo -e "${GREEN}+ NEW:${NC} $skill"
                if [ "$dry_run" != "true" ]; then
                    cp -r "$skill_dir" "$AGENTS_REPO/$skill"
                    unignore_private_configs "$AGENTS_REPO/$skill"
                    ln -sf "../../../agents/.agents/skills/$skill" "$CLAUDE_REPO/$skill"
                fi
                changes=$((changes + 1))
            fi
        fi
    done

    # 2. Find removed skills (in repo but not locally)
    for skill_dir in "$AGENTS_REPO"/*/; do
        skill=$(basename "$skill_dir")
        if [ ! -d "$AGENTS_LOCAL/$skill" ]; then
            echo -e "${RED}- REMOVED:${NC} $skill"
            if [ "$dry_run" != "true" ]; then
                rm -rf "$AGENTS_REPO/$skill"
                rm -f "$CLAUDE_REPO/$skill"
            fi
            changes=$((changes + 1))
        fi
    done

    # 3. Find modified skills (real local files that differ from repo)
    for skill_dir in "$AGENTS_LOCAL"/*/; do
        skill=$(basename "$skill_dir")
        if [ -f "$skill_dir/SKILL.md" ] && [ ! -L "$skill_dir/SKILL.md" ] && [ -d "$AGENTS_REPO/$skill" ]; then
            if ! diff -rq "$skill_dir" "$AGENTS_REPO/$skill" &>/dev/null; then
                echo -e "${YELLOW}~ MODIFIED:${NC} $skill"
                if [ "$dry_run" != "true" ]; then
                    rm -rf "$AGENTS_REPO/$skill"
                    cp -r "$skill_dir" "$AGENTS_REPO/$skill"
                    unignore_private_configs "$AGENTS_REPO/$skill"
                fi
                changes=$((changes + 1))
            fi
        fi
    done

    # 4. Check settings.json and CLAUDE.md changes (stow symlinks, so changes are already in repo)
    cd "$DOTFILES_DIR"
    if ! git diff --quiet 2>/dev/null; then
        echo -e "${YELLOW}~ MODIFIED:${NC} settings/config files"
        changes=$((changes + 1))
    fi

    return $changes
}

case "${1:-}" in
    status)
        echo "=== Dotfiles Sync Status ==="
        sync_skills true || true
        echo ""
        cd "$DOTFILES_DIR" && git status --short
        ;;
    *)
        echo "=== Syncing Dotfiles ==="
        set +e
        sync_skills false
        changes=$?
        set -e

        cd "$DOTFILES_DIR"

        # Restow to pick up new symlinks
        if [ $changes -gt 0 ]; then
            echo "Restowing..."
            stow --no-folding agents 2>/dev/null || true
            stow --no-folding claude 2>/dev/null || true
        fi

        # Check if there's anything to commit
        git add -A
        if git diff --cached --quiet; then
            echo "Nothing to sync."
            exit 0
        fi

        # Commit and push
        git commit -m "sync: $(date +%Y-%m-%d) skills and config update"
        git push
        echo -e "${GREEN}=== Synced! ===${NC}"
        ;;
esac
