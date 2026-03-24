# Dotfiles

English | [中文](README.zh-CN.md)

> **Cross-machine config sync** — Claude Code, Zsh, Tmux, Starship, Ghostty, and iTerm2, powered by [GNU Stow](https://www.gnu.org/software/stow/).

## Quick Start

```bash
git clone git@github.com:jiahao-shao1/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./install.sh
```

The installer will:

1. Install GNU Stow (brew on macOS, from source on Linux)
2. Set up Zsh with Oh My Zsh, plugins, and Starship prompt
3. Install Ghostty companion tools (macOS: fastfetch, btop, Maple Mono font)
4. Merge any existing local skills into the repo
6. Back up existing configs to `~/.dotfiles-backup-<timestamp>/`
7. Create symlinks via `stow` for all managed packages

## What's Inside

```
dotfiles/
├── agents/          # ~/.agents — Claude Code agent skills (21+)
├── claude/          # ~/.claude — settings.json, CLAUDE.md, skills symlinks
├── zsh/             # ~/.zshrc.shared — shared shell config
├── tmux/            # ~/.tmux.conf
├── starship/        # ~/.config/starship.toml
├── ghostty/         # ~/.config/ghostty/config (macOS)
├── iterm2/          # iTerm2 preferences (macOS)
├── install.sh       # One-time setup
├── dot-sync.sh      # Skill & config sync script
└── claude-notify.sh # Cross-platform notifications
```

## How Stow Works

Each top-level directory mirrors a path under `$HOME`. Stow creates **file-level symlinks** (`--no-folding`) so that:

- `~/dotfiles/agents/.agents/skills/xxx/` → `~/.agents/skills/xxx/`
- `~/dotfiles/claude/.claude/settings.json` → `~/.claude/settings.json`
- Skills in `~/.claude/skills/` are repo-internal symlinks pointing to `agents/.agents/skills/`

This means **editing `~/.claude/settings.json` edits the repo file directly** — no manual copy needed.

## What Gets Synced

| Synced | Not Synced |
|--------|------------|
| `~/.agents/skills/` | `~/.claude/history.jsonl` |
| `~/.claude/settings.json` | `~/.claude/.credentials.json` |
| `~/.claude/CLAUDE.md` | `~/.claude/projects/` |
| `~/.claude/skills/` | Other runtime files |
| `~/.zshrc.shared` | `~/.zshrc` (machine-specific) |
| `~/.tmux.conf` | |
| `~/.config/starship.toml` | |
| `~/.config/ghostty/config` | |

## Daily Use

Syncing is **fully automatic** via Claude Code hooks (configured in `settings.json`):

- **Session start** → `git pull` (fetches latest from remote)
- **Session stop** → `dot-sync.sh` + notification (syncs changes, commits, pushes)

Manual commands:

```bash
dot-sync           # sync now: detect changes → commit → push
dot-sync status    # dry run: show what would be synced
```

## Skill Submodules

6 skills are managed as git submodules (independent repos):

| Skill | Description | GitHub Repo |
|-------|-------------|-------------|
| `cmux` | Terminal orchestration, split panes, browser | [cmux-skill](https://github.com/jiahao-shao1/cmux-skill) |
| `daily-summary` | Daily work summary aggregation | [daily-summary-skill](https://github.com/jiahao-shao1/daily-summary-skill) |
| `notion-lifeos` | Notion PARA life management | [notion-lifeos-skill](https://github.com/jiahao-shao1/notion-lifeos-skill) |
| `robby-cluster-connect` | GPU cluster remote operations | [robby-cluster-connect](https://github.com/jiahao-shao1/robby-cluster-connect) |
| `scholar-inbox` | Scholar Inbox CLI — daily paper digest | [scholar-inbox-cli](https://github.com/jiahao-shao1/scholar-inbox-cli) |
| `web-fetcher` | 5-layer web content extraction | [web-fetcher](https://github.com/jiahao-shao1/web-fetcher) |

### Switching submodule URLs (internal-git ↔ GitHub)

On work device, submodules point to internal-git. On personal Mac, they point to GitHub. Switch with one command:

```bash
# Work device → Personal Mac: switch to GitHub
./scripts/switch-submodule-urls.sh github

# Personal Mac → Work device: switch to internal-git
./scripts/switch-submodule-urls.sh internal-git
```

To add a new mapping when repo names differ between internal-git and GitHub, edit the `internal-git_to_github()` and `github_to_internal-git()` functions in `scripts/switch-submodule-urls.sh`.

## Adding / Removing Skills

```bash
# Install a new skill
npx skills add vercel-labs/agent-skills --skill frontend-design -a claude-code
# Auto-synced on next Claude Code exit, or run: dot-sync

# Remove a skill
npx skills remove frontend-design
# Auto-synced on next Claude Code exit, or run: dot-sync
```

## Shell Config Highlights

- **Zsh**: Oh My Zsh + zsh-syntax-highlighting + zsh-autosuggestions + you-should-use
- **Tmux**: Backtick (`` ` ``) prefix, vi mode, mouse support, macOS clipboard integration
- **Starship**: Catppuccin Mocha theme, git status, language version display, command duration
- **Ghostty**: Catppuccin Mocha, Maple Mono NF CN font, 85% opacity with blur, 25M scrollback

## Notifications

`claude-notify.sh` provides cross-platform notifications when Claude Code finishes or needs attention:

- **macOS**: Native system notifications via `osascript`
- **Linux**: Telegram bot messages

## Platform Support

| Feature | macOS | Linux |
|---------|-------|-------|
| Stow + symlinks | ✅ | ✅ |
| Claude Code skills | ✅ | ✅ |
| Zsh + Starship | ✅ | ✅ |
| Tmux | ✅ | ✅ |
| Ghostty | ✅ | — |
| iTerm2 | ✅ | — |
| Notifications | Native | Telegram |
