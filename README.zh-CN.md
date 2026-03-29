# Dotfiles

[English](README.md) | 中文

> **跨机器配置同步** — Claude Code、Zsh、Tmux、Starship、Ghostty 和 iTerm2，基于 [GNU Stow](https://www.gnu.org/software/stow/)。

## 快速开始

```bash
git clone git@github.com:jiahao-shao1/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./install.sh && bash scripts/bootstrap.sh
```

`install.sh` 安装基础依赖：

1. 安装 GNU Stow（macOS 用 brew，Linux 从源码编译）
2. 配置 Zsh：Oh My Zsh、插件、Starship 提示符
3. 安装终端工具（lazygit、yazi、zoxide）及 yazi 插件
4. 安装 Ghostty 配套工具（macOS：fastfetch、btop、Maple Mono 字体、cmux）
5. 备份已有配置到 `~/.dotfiles-backup-<timestamp>/`
6. 通过 `stow` 创建所有软链接

`bootstrap.sh` 配置 skills：

1. Stow 所有 dotfile 包
2. 克隆 [sjh-skills](https://github.com/jiahao-shao1/sjh-skills) monorepo
3. 为个人/公司 skills 创建软链接
4. 通过 `npx skills add` 安装所有第三方 skills

## 仓库结构

```
dotfiles/
├── claude/          # ~/.claude — settings.json、CLAUDE.md、skills、rules
├── zsh/             # ~/.zshrc.shared — 共享 shell 配置
├── tmux/            # ~/.tmux.conf
├── starship/        # ~/.config/starship.toml
├── ghostty/         # ~/.config/ghostty/config（macOS）
├── iterm2/          # iTerm2 偏好设置（macOS）
├── scripts/         # bootstrap.sh、setup-skills.sh、install-skills.sh
├── install.sh       # 一次性安装脚本（依赖 + stow）
├── dot-sync.sh      # 配置同步脚本
└── claude-notify.sh # 跨平台通知工具
```

## Stow 工作原理

每个顶层目录映射到 `$HOME` 下的对应路径。Stow 使用 `--no-folding` 创建**文件级别的软链接**：

- `~/dotfiles/claude/.claude/settings.json` → `~/.claude/settings.json`
- `~/dotfiles/claude/.claude/CLAUDE.md` → `~/.claude/CLAUDE.md`
- `~/dotfiles/zsh/.zshrc.shared` → `~/.zshrc.shared`

因此**直接编辑 `~/.claude/settings.json` 就是在编辑仓库中的文件**，无需手动拷贝。

## 同步范围

| 同步 | 不同步 |
|------|--------|
| `~/.claude/settings.json` | `~/.claude/history.jsonl` |
| `~/.claude/CLAUDE.md` | `~/.claude/.credentials.json` |
| `~/.claude/skills/` | `~/.claude/projects/` |
| `~/.claude/rules/` | 其他运行时文件 |
| `~/.zshrc.shared` | `~/.zshrc`（机器特定） |
| `~/.tmux.conf` | |
| `~/.config/starship.toml` | |
| `~/.config/ghostty/config` | |

## 日常使用

同步**完全自动化**，通过 Claude Code hooks（配置在 `settings.json` 中）：

- **会话开始** → `git pull`（拉取远程最新）
- **会话结束** → `dot-sync.sh` + 通知（同步变更、提交、推送）

手动命令：

```bash
dot-sync           # 立即同步：检测变更 → 提交 → 推送
dot-sync status    # 预览模式：显示待同步的变更
```

## Skill 管理

Skill 来自三个来源：

| 来源 | 管理方式 | Skills |
|------|---------|--------|
| **第三方** | `npx skills add`（[install-skills.sh](scripts/install-skills.sh)） | brainstorming, writing-plans, executing-plans, dispatching-parallel-agents, subagent-driven-development, using-git-worktrees, frontend-design, skill-creator, find-skills, frontend-slides, baoyu-infographic, baoyu-xhs-images, playwright-cli, notebooklm |
| **个人** | [sjh-skills](https://github.com/jiahao-shao1/sjh-skills) monorepo（symlink） | scholar-agent, cmux, codex-review, daily-summary, init-project, notion-lifeos, project-review, web-fetcher |
| **私有** | 独立私有仓库（symlink，.gitignore 排除） | — |

个人和私有 skill 存放在独立的 monorepo 中，通过 symlink 链接（不再使用 submodule）。克隆后运行：

```bash
./scripts/setup-skills.sh
```

会自动创建 `~/.claude/skills/` 和 `~/.agents/skills/` 到 monorepo 目录的软链接。

## 添加 / 删除 Skill

```bash
# 安装新 skill
npx skills add vercel-labs/agent-skills --skill frontend-design -a claude-code
# 下次退出 Claude Code 时自动同步，或手动执行：dot-sync

# 删除 skill
npx skills remove frontend-design
# 下次退出 Claude Code 时自动同步，或手动执行：dot-sync
```

## Shell 配置亮点

- **Zsh**：Oh My Zsh + zsh-syntax-highlighting + zsh-autosuggestions + you-should-use + zoxide
- **Tmux**：反引号（`` ` ``）前缀键、vi 模式、鼠标支持、macOS 剪贴板集成、lazygit 弹窗（`` ` + g ``）
- **终端工具**：lazygit（Git TUI）、yazi（文件管理器，集成 git + lazygit 插件）、zoxide（智能 cd）
- **Starship**：Catppuccin Mocha 主题、git 状态、语言版本显示、命令耗时
- **Ghostty**：Catppuccin Mocha、Maple Mono NF CN 字体、85% 透明度 + 模糊、25M 回滚缓冲区

## 通知机制

`claude-notify.sh` 在 Claude Code 完成工作或需要关注时发送跨平台通知：

- **macOS**：通过 `osascript` 发送系统原生通知
- **Linux**：可配置（Telegram 等）

## 平台支持

| 功能 | macOS | Linux |
|------|-------|-------|
| Stow + 软链接 | ✅ | ✅ |
| Claude Code skills | ✅ | ✅ |
| Zsh + Starship | ✅ | ✅ |
| Tmux | ✅ | ✅ |
| lazygit / yazi / zoxide | ✅ | 手动安装 |
| Ghostty | ✅ | — |
| iTerm2 | ✅ | — |
| 通知 | 系统原生 | 可配置 |

## 许可证

[MIT](LICENSE)
