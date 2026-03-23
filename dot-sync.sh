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
CLAUDE_LOCAL="$HOME/.claude/skills"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

is_gitignored() {
    cd "$DOTFILES_DIR" && git check-ignore -q "agents/.agents/skills/$1" 2>/dev/null
}

is_submodule() {
    cd "$DOTFILES_DIR" && git submodule status -- "agents/.agents/skills/$1" &>/dev/null 2>&1
}

# Remove private config ignores from skill .gitignore (dotfiles repo is private, no need to ignore)
unignore_private_configs() {
    local gitignore="$1/.gitignore"
    [ -f "$gitignore" ] && sed -i '' '/^CONFIG\.private\.md$/d' "$gitignore"
}

# Check if a local skill dir is a "real" (unmanaged) skill that dot-sync should handle
is_unmanaged_skill() {
    local skill_dir="$1"
    # Skip if dir itself is a symlink
    [ -L "${skill_dir%/}" ] && return 1
    # Skip if it has its own git repo (managed externally)
    [ -d "$skill_dir/.git" ] && return 1
    # Must have a real (non-symlink) SKILL.md
    [ -f "$skill_dir/SKILL.md" ] && [ ! -L "$skill_dir/SKILL.md" ] && return 0
    return 1
}

import_skill() {
    local skill_dir="$1"
    local skill="$2"
    local dry_run="$3"
    echo -e "${GREEN}+ NEW:${NC} $skill"
    if [ "$dry_run" != "true" ]; then
        cp -r "$skill_dir" "$AGENTS_REPO/$skill"
        unignore_private_configs "$AGENTS_REPO/$skill"
        ln -sf "../../../agents/.agents/skills/$skill" "$CLAUDE_REPO/$skill"
    fi
}

sync_skills() {
    local dry_run=$1
    local changes=0

    # 1. Find new local skills from ~/.agents/skills/ (real dirs, not stow-managed)
    for skill_dir in "$AGENTS_LOCAL"/*/; do
        skill=$(basename "$skill_dir")
        is_unmanaged_skill "$skill_dir" || continue
        is_gitignored "$skill" && continue
        if [ ! -d "$AGENTS_REPO/$skill" ]; then
            import_skill "$skill_dir" "$skill" "$dry_run"
            changes=$((changes + 1))
        fi
    done

    # 1b. Find new local skills from ~/.claude/skills/ (created directly there)
    for skill_dir in "$CLAUDE_LOCAL"/*/; do
        skill=$(basename "$skill_dir")
        is_unmanaged_skill "$skill_dir" || continue
        is_gitignored "$skill" && continue
        if [ ! -d "$AGENTS_REPO/$skill" ]; then
            import_skill "$skill_dir" "$skill" "$dry_run"
            changes=$((changes + 1))
        fi
    done

    # 2. Find removed skills (in repo but not locally)
    for skill_dir in "$AGENTS_REPO"/*/; do
        skill=$(basename "$skill_dir")
        # Skip submodules (managed by git, not dot-sync)
        is_submodule "$skill" && continue
        if [ ! -d "$AGENTS_LOCAL/$skill" ] && [ ! -d "$CLAUDE_LOCAL/$skill" ]; then
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
        is_unmanaged_skill "$skill_dir" || continue
        is_submodule "$skill" && continue
        if [ -d "$AGENTS_REPO/$skill" ]; then
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

    # 3b. Find modified skills from ~/.claude/skills/
    for skill_dir in "$CLAUDE_LOCAL"/*/; do
        skill=$(basename "$skill_dir")
        is_unmanaged_skill "$skill_dir" || continue
        is_submodule "$skill" && continue
        if [ -d "$AGENTS_REPO/$skill" ]; then
            if ! diff -rq "$skill_dir" "$AGENTS_REPO/$skill" &>/dev/null; then
                echo -e "${YELLOW}~ MODIFIED:${NC} $skill (from ~/.claude/skills/)"
                if [ "$dry_run" != "true" ]; then
                    rm -rf "$AGENTS_REPO/$skill"
                    cp -r "$skill_dir" "$AGENTS_REPO/$skill"
                    unignore_private_configs "$AGENTS_REPO/$skill"
                fi
                changes=$((changes + 1))
            fi
        fi
    done

    # 4. Ensure every agents skill has a corresponding claude symlink
    for skill_dir in "$AGENTS_REPO"/*/; do
        skill=$(basename "$skill_dir")
        if [ ! -e "$CLAUDE_REPO/$skill" ]; then
            echo -e "${GREEN}+ LINK:${NC} $skill"
            if [ "$dry_run" != "true" ]; then
                ln -sf "../../../agents/.agents/skills/$skill" "$CLAUDE_REPO/$skill"
            fi
            changes=$((changes + 1))
        fi
    done

    # 5. Check settings.json and CLAUDE.md changes (stow symlinks, so changes are already in repo)
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

        # Convert real local skill dirs to stow symlinks
        # (remove local copies that already exist in repo so stow can create symlinks)
        for search_dir in "$AGENTS_LOCAL" "$CLAUDE_LOCAL"; do
            for skill_dir in "$search_dir"/*/; do
                [ -L "${skill_dir%/}" ] && continue
                [ -d "$skill_dir/.git" ] && continue
                skill=$(basename "$skill_dir")
                if [ -f "$skill_dir/SKILL.md" ] && [ ! -L "$skill_dir/SKILL.md" ] && [ -d "$AGENTS_REPO/$skill" ]; then
                    is_gitignored "$skill" && continue
                    is_submodule "$skill" && continue
                    echo -e "${GREEN}→ STOW:${NC} $skill"
                    rm -rf "$skill_dir"
                    changes=$((changes + 1))
                fi
            done
        done

        # Restow to pick up new symlinks
        if [ $changes -gt 0 ]; then
            echo "Restowing..."
            stow -R --no-folding agents 2>/dev/null || true
            stow -R --no-folding claude 2>/dev/null || true
        fi

        # Check if there's anything to commit
        git add -A
        if git diff --cached --quiet; then
            echo "Nothing to sync."
            exit 0
        fi

        # Commit and push to all configured remotes
        git commit -m "sync: $(date +%Y-%m-%d) skills and config update"

        # Determine push targets by machine type
        case "$(hostname)" in
            MacBook-Pro*)  PUSH_REMOTES="internal-git" ;;  # work device → internal-git only
            *)             PUSH_REMOTES="origin" ;;    # personal Mac / workstation → GitHub
        esac

        pushed=0
        for remote in $PUSH_REMOTES; do
            if git remote get-url "$remote" &>/dev/null; then
                echo "Pushing to $remote..."
                BRANCH="$(git symbolic-ref --short HEAD)"
                if git push "$remote" "$BRANCH" 2>/dev/null; then
                    echo -e "${GREEN}  ✓ $remote${NC}"
                    pushed=$((pushed + 1))
                else
                    echo -e "${YELLOW}  ✗ $remote (skipped)${NC}"
                fi
            fi
        done

        if [ $pushed -eq 0 ]; then
            echo -e "${RED}No remote pushed successfully.${NC}"
            exit 1
        fi
        echo -e "${GREEN}=== Synced! ===${NC}"
        ;;
esac
