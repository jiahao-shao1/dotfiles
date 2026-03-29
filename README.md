# Dotfiles

English | [中文](README.zh-CN.md)

> **Cross-machine config sync** — Claude Code, Zsh, Tmux, Starship, Ghostty, and iTerm2, powered by [GNU Stow](https://www.gnu.org/software/stow/).

## Quick Start

```bash
git clone git@github.com:jiahao-shao1/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./install.sh && bash scripts/bootstrap.sh
```

`install.sh` sets up base dependencies:

1. Install GNU Stow (brew on macOS, from source on Linux)
2. Set up Zsh with Oh My Zsh, plugins, and Starship prompt
3. Install terminal tools (lazygit, yazi, zoxide) and yazi plugins
4. Install Ghostty companion tools (macOS: fastfetch, btop, Maple Mono font, cmux)
5. Back up existing configs to `~/.dotfiles-backup-<timestamp>/`
6. Create symlinks via `stow` for all managed packages

`bootstrap.sh` sets up skills:

1. Stow all dotfile packages
2. Clone [sjh-skills](https://github.com/jiahao-shao1/sjh-skills) monorepo
3. Create symlinks for personal/company skills
4. Install all third-party skills via `npx skills add`

## What's Inside

```
dotfiles/
├── claude/          # ~/.claude — settings.json, CLAUDE.md, skills, rules
├── zsh/             # ~/.zshrc.shared — shared shell config
├── tmux/            # ~/.tmux.conf
├── starship/        # ~/.config/starship.toml
├── ghostty/         # ~/.config/ghostty/config (macOS)
├── iterm2/          # iTerm2 preferences (macOS)
├── scripts/         # bootstrap.sh, setup-skills.sh, install-skills.sh
├── install.sh       # One-time setup (dependencies + stow)
├── dot-sync.sh      # Config sync script
└── claude-notify.sh # Cross-platform notifications
```

## How Stow Works

Each top-level directory mirrors a path under `$HOME`. Stow creates **file-level symlinks** (`--no-folding`) so that:

- `~/dotfiles/claude/.claude/settings.json` → `~/.claude/settings.json`
- `~/dotfiles/claude/.claude/CLAUDE.md` → `~/.claude/CLAUDE.md`
- `~/dotfiles/zsh/.zshrc.shared` → `~/.zshrc.shared`

This means **editing `~/.claude/settings.json` edits the repo file directly** — no manual copy needed.

## What Gets Synced

| Synced | Not Synced |
|--------|------------|
| `~/.claude/settings.json` | `~/.claude/history.jsonl` |
| `~/.claude/CLAUDE.md` | `~/.claude/.credentials.json` |
| `~/.claude/skills/` | `~/.claude/projects/` |
| `~/.claude/rules/` | Other runtime files |
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

## Skill Management

Skills come from three sources:

| Source | Managed by | Skills |
|--------|-----------|--------|
| **Third-party** | `npx skills add` ([install-skills.sh](scripts/install-skills.sh)) | brainstorming, writing-plans, executing-plans, dispatching-parallel-agents, subagent-driven-development, using-git-worktrees, frontend-design, skill-creator, find-skills, frontend-slides, baoyu-infographic, baoyu-xhs-images, playwright-cli, notebooklm |
| **Personal** | [sjh-skills](https://github.com/jiahao-shao1/sjh-skills) monorepo (symlink) | scholar-agent, cmux, codex-review, daily-summary, init-project, notion-lifeos, project-review, web-fetcher |
| **Private** | Separate private repo (symlink, .gitignore'd) | — |

Personal and private skills live in separate monorepos and are linked via symlinks (not submodules). Run the setup script after cloning:

```bash
./scripts/setup-skills.sh
```

This creates symlinks from `~/.claude/skills/` and `~/.agents/skills/` to the monorepo directories.

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

- **Zsh**: Oh My Zsh + zsh-syntax-highlighting + zsh-autosuggestions + you-should-use + zoxide
- **Tmux**: Backtick (`` ` ``) prefix, vi mode, mouse support, macOS clipboard integration, lazygit popup (`` ` + g ``)
- **Terminal tools**: lazygit (git TUI), yazi (file manager with git + lazygit plugins), zoxide (smart cd)
- **Starship**: Catppuccin Mocha theme, git status, language version display, command duration
- **Ghostty**: Catppuccin Mocha, Maple Mono NF CN font, 85% opacity with blur, 25M scrollback

## Notifications

`claude-notify.sh` provides cross-platform notifications when Claude Code finishes or needs attention:

- **macOS**: Native system notifications via `osascript`
- **Linux**: Configurable (Telegram, etc.)

## Platform Support

| Feature | macOS | Linux |
|---------|-------|-------|
| Stow + symlinks | ✅ | ✅ |
| Claude Code skills | ✅ | ✅ |
| Zsh + Starship | ✅ | ✅ |
| Tmux | ✅ | ✅ |
| Ghostty | ✅ | — |
| iTerm2 | ✅ | — |
| Notifications | Native | Configurable |

## License

[MIT](LICENSE)
