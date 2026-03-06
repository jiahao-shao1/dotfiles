# Dotfiles

Claude Code config sync across machines using GNU Stow.

## One-liner Install

```bash
git clone git@github.com:jiahao-shao1/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./install.sh
```

- Automatically installs GNU Stow (brew on macOS, from source on Linux)
- Merges local skills into repo (won't overwrite existing skills)
- Backs up existing configs to `~/.dotfiles-backup-<timestamp>/`

## What Gets Synced

| Synced | Not Synced |
|--------|------------|
| `~/.agents/skills/` | `~/.claude/history.jsonl` |
| `~/.claude/settings.json` | `~/.claude/.credentials.json` |
| `~/.claude/CLAUDE.md` | `~/.claude/projects/` |
| `~/.claude/skills/` | Other runtime files |

## Daily Use

Syncing is fully automatic:

- **Start** Claude Code → auto `git pull` (SessionStart hook)
- **Exit** Claude Code → auto `dot-sync` (Stop hook)

Manual commands:

```bash
dot-status    # show pending changes
dot-sync      # sync now (detect new/removed/modified skills → commit → push)
```

## Adding/Removing Skills

```bash
# Install a new skill (works with npx skills as usual)
npx skills add vercel-labs/agent-skills --skill frontend-design -a claude-code
# Auto-synced on next Claude Code exit, or run: dot-sync

# Remove a skill
npx skills remove frontend-design
# Auto-synced on next Claude Code exit, or run: dot-sync
```
