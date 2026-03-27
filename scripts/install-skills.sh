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

# obra/superpowers (5 skills: brainstorming, writing-plans, executing-plans,
#   dispatching-parallel-agents, subagent-driven-development, using-git-worktrees)
echo "[1/7] obra/superpowers..."
npx skills add obra/superpowers \
  --skill brainstorming \
  --skill writing-plans \
  --skill executing-plans \
  --skill dispatching-parallel-agents \
  --skill subagent-driven-development \
  --skill using-git-worktrees \
  $COMMON_FLAGS

# anthropics/skills (frontend-design, skill-creator)
echo "[2/7] anthropics/skills..."
npx skills add anthropics/skills --skill frontend-design --skill skill-creator $COMMON_FLAGS

# vercel-labs/skills (find-skills)
echo "[3/7] vercel-labs/skills..."
npx skills add vercel-labs/skills --skill find-skills $COMMON_FLAGS

# zarazhangrui/frontend-slides
echo "[4/7] zarazhangrui/frontend-slides..."
npx skills add zarazhangrui/frontend-slides $COMMON_FLAGS

# jimliu/baoyu-skills (baoyu-infographic, baoyu-xhs-images)
echo "[5/7] jimliu/baoyu-skills..."
npx skills add jimliu/baoyu-skills \
  --skill baoyu-infographic \
  --skill baoyu-xhs-images \
  $COMMON_FLAGS

# microsoft/playwright-cli
echo "[6/7] microsoft/playwright-cli..."
npx skills add microsoft/playwright-cli $COMMON_FLAGS

# teng-lin/notebooklm-py
echo "[7/7] teng-lin/notebooklm-py..."
npx skills add teng-lin/notebooklm-py $COMMON_FLAGS

echo ""
echo "Done! Verify with: npx skills list -g"
echo ""
echo "To update all skills later: npx skills update"
