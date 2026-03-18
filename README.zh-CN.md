# Dotfiles

[English](README.md) | 中文

> **跨机器配置同步** — Claude Code、Zsh、Tmux、Starship、Ghostty 和 iTerm2，基于 [GNU Stow](https://www.gnu.org/software/stow/)。

## 快速开始

```bash
git clone git@github.com:jiahao-shao1/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./install.sh
```

安装脚本会自动完成：

1. 安装 GNU Stow（macOS 用 brew，Linux 从源码编译）
2. 配置 Zsh：Oh My Zsh、插件、Starship 提示符
3. 安装 Ghostty 配套工具（macOS：fastfetch、btop、Maple Mono 字体）
4. 安装 [Agent Reach](https://github.com/anthropics/agent-reach) 提供联网能力
5. 将本地已有的 skill 合并到仓库
6. 备份已有配置到 `~/.dotfiles-backup-<timestamp>/`
7. 通过 `stow` 创建所有软链接

## 仓库结构

```
dotfiles/
├── agents/          # ~/.agents — Claude Code agent skills（21+）
├── claude/          # ~/.claude — settings.json、CLAUDE.md、skills 软链接
├── zsh/             # ~/.zshrc.shared — 共享 shell 配置
├── tmux/            # ~/.tmux.conf
├── starship/        # ~/.config/starship.toml
├── ghostty/         # ~/.config/ghostty/config（macOS）
├── iterm2/          # iTerm2 偏好设置（macOS）
├── install.sh       # 一次性安装脚本
├── dot-sync.sh      # Skill 和配置同步脚本
└── claude-notify.sh # 跨平台通知工具
```

## Stow 工作原理

每个顶层目录映射到 `$HOME` 下的对应路径。Stow 使用 `--no-folding` 创建**文件级别的软链接**：

- `~/dotfiles/agents/.agents/skills/xxx/` → `~/.agents/skills/xxx/`
- `~/dotfiles/claude/.claude/settings.json` → `~/.claude/settings.json`
- `~/.claude/skills/` 下的 skill 是仓库内部的软链接，指向 `agents/.agents/skills/`

因此**直接编辑 `~/.claude/settings.json` 就是在编辑仓库中的文件**，无需手动拷贝。

## 同步范围

| 同步 | 不同步 |
|------|--------|
| `~/.agents/skills/` | `~/.claude/history.jsonl` |
| `~/.claude/settings.json` | `~/.claude/.credentials.json` |
| `~/.claude/CLAUDE.md` | `~/.claude/projects/` |
| `~/.claude/skills/` | 其他运行时文件 |
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

- **Zsh**：Oh My Zsh + zsh-syntax-highlighting + zsh-autosuggestions + you-should-use
- **Tmux**：反引号（`` ` ``）前缀键、vi 模式、鼠标支持、macOS 剪贴板集成
- **Starship**：Catppuccin Mocha 主题、git 状态、语言版本显示、命令耗时
- **Ghostty**：Catppuccin Mocha、Maple Mono NF CN 字体、85% 透明度 + 模糊、25M 回滚缓冲区

## 通知机制

`claude-notify.sh` 在 Claude Code 完成工作或需要关注时发送跨平台通知：

- **macOS**：通过 `osascript` 发送系统原生通知
- **Linux**：通过 Telegram Bot 发送消息

## 平台支持

| 功能 | macOS | Linux |
|------|-------|-------|
| Stow + 软链接 | ✅ | ✅ |
| Claude Code skills | ✅ | ✅ |
| Zsh + Starship | ✅ | ✅ |
| Tmux | ✅ | ✅ |
| Ghostty | ✅ | — |
| iTerm2 | ✅ | — |
| 通知 | 系统原生 | Telegram |
