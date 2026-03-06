# Dotfiles

Claude Code config sync across machines using GNU Stow.

## Install

```bash
git clone git@github.com:jiahao-shao1/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## Packages

- `agents` — `~/.agents/skills/` (skill source files)
- `claude` — `~/.claude/settings.json`, `CLAUDE.md`, `skills/` symlinks

## Daily use

- Auto-pull: Claude Code SessionStart hook runs `git pull --ff-only`
- Manual push: `cd ~/dotfiles && git add -A && git commit -m "update" && git push`
