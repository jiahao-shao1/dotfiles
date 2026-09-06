#!/bin/bash
# One-click install all third-party Claude Code skills via npx
# Run: bash ~/dotfiles/scripts/install-skills.sh
#
# Flags:
#   -y: skip confirmation prompts
#   -g: global install (~/.claude/skills/ and ~/.agents/skills/)
#   -a claude-code: only install for Claude Code agent
#
# Symlink mode is default (recommended) — single source of truth, easy updates.
# Use --copy if symlinks aren't supported on your system.

set -e

COMMON_FLAGS="-y -g -a claude-code -a codex"

echo "Installing third-party skills for Claude Code..."
echo ""
echo "Note: sjh-skills is installed via Claude Code plugin (superpowers dropped 2026-09)."
echo "      Plugins are declared in settings.json and auto-synced via stow."
echo ""

# anthropics/skills (frontend-design, skill-creator)
echo "[1/5] anthropics/skills..."
npx skills add anthropics/skills --skill frontend-design --skill skill-creator $COMMON_FLAGS

# vercel-labs/skills (find-skills)
echo "[2/5] vercel-labs/skills..."
npx skills add vercel-labs/skills --skill find-skills $COMMON_FLAGS

# zarazhangrui/frontend-slides
echo "[3/5] zarazhangrui/frontend-slides..."
npx skills add zarazhangrui/frontend-slides $COMMON_FLAGS

# microsoft/playwright-cli
echo "[4/5] microsoft/playwright-cli..."
npx skills add microsoft/playwright-cli $COMMON_FLAGS

# blader/humanizer
echo "[5/5] blader/humanizer..."
npx skills add https://github.com/blader/humanizer --skill humanizer $COMMON_FLAGS

echo ""
echo "Done! Verify with: npx skills list -g"
echo ""
echo "To update all skills later: npx skills update"
