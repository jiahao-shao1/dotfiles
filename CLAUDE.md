# dotfiles Project Guide

## Project Overview

**dotfiles** 是一个跨机器配置同步项目，通过 GNU Stow 管理 symlink。

管理的配置包括：Claude Code（agents、skills、settings）、Zsh、Tmux、Starship、Ghostty、iTerm2。

核心机制：
- 每个顶层目录映射 `$HOME` 下的路径，Stow 以 `--no-folding` 创建文件级 symlink
- 通过 Claude Code hooks 实现自动同步（session start 拉取，session stop 推送）
- `dot-sync.sh` 处理变更检测、commit、push
- `claude-notify.sh` 提供跨平台通知（macOS 原生 / Linux Telegram）

## Directory Structure

### Stow 包（每个目录 = 一个 stow 包）

| 目录 | 目标路径 | 内容 |
|------|----------|------|
| `agents/` | `~/.agents/` | Claude Code agent skills（21+） |
| `claude/` | `~/.claude/` | settings.json、CLAUDE.md、skills symlinks |
| `zsh/` | `~/` | `.zshrc.shared` — 跨机器共享的 shell 配置 |
| `tmux/` | `~/` | `.tmux.conf` |
| `starship/` | `~/.config/` | `starship.toml`（Catppuccin Mocha 主题） |
| `ghostty/` | `~/.config/` | Ghostty 终端配置（macOS） |
| `iterm2/` | `~/` | iTerm2 preferences plist |

### 脚本

| 文件 | 用途 |
|------|------|
| `install.sh` | 一次性安装：Stow、Zsh 插件、Ghostty 工具、symlink 创建 |
| `dot-sync.sh` | 同步脚本：检测变更 → commit → push |
| `claude-notify.sh` | 跨平台通知（macOS osascript / Linux Telegram） |

## Dev Workflow

```
编辑配置 → stow --no-folding <包名> → 验证 symlink → dot-sync（自动或手动）
```

### 常见操作

| 场景 | 步骤 |
|------|------|
| 修改现有配置 | 直接编辑 `~/dotfiles/<包>/` 下的文件（symlink 自动生效） |
| 添加新 skill | `npx skills add ...` → `dot-sync` |
| 添加新 stow 包 | 创建目录结构 → `stow --no-folding <包名>` → 更新 `install.sh` |
| 新机器部署 | `git clone` → `./install.sh` |

### 自动同步

已通过 `claude/.claude/settings.json` 中的 hooks 配置：
- **Session start** → `git pull`（拉取远端最新）
- **Session stop** → `dot-sync.sh` + 通知（同步变更、commit、push）

## Dev Guide

### 环境依赖

- GNU Stow（`brew install stow` / 源码编译）
- Zsh + Oh My Zsh
- Node.js（用于 `npx skills` 命令）

### Stow 使用

```bash
# 部署单个包
stow --no-folding <包名>

# 部署所有包（install.sh 中的逻辑）
for pkg in agents claude zsh tmux starship ghostty; do
  stow --no-folding "$pkg"
done

# 取消部署
stow -D <包名>
```

### Skill 管理

- Skill 源文件在 `agents/.agents/skills/<name>/SKILL.md`
- `claude/.claude/skills/` 下创建 symlink 指向 `../../../agents/.agents/skills/<name>`
- internal skill 需在 `.gitignore` 中排除

### 同步

```bash
dot-sync           # 立即同步：检测变更 → commit → push
dot-sync status    # 干运行：显示会同步什么
```

## Experience Capture

When a non-trivial problem is solved during a session (debugging, workaround, design trade-off, etc.), **immediately** write the experience to the corresponding domain file in `.claude/knowledge/` — don't wait until the session ends.

### Writing Guidelines

- **File naming**: by domain topic, e.g., `api-integration.md`, `deployment.md`. Create new files for new domains.
- **Entry format**:

```markdown
## YYYY-MM-DD: Brief Title

**Problem**: what happened
**Solution**: how it was resolved
**Lesson**: what to watch for next time
**Files**: code files involved
**Commit**: related git commit hash
```

### What to Write

- Bugs and root causes discovered during debugging
- Non-obvious workarounds or API behaviors
- Design decisions and their trade-offs
- Parameter tuning experiences

### What Not to Write

- Pure code change records (tracked by git log)
- Content already in documentation
- Temporary exploratory attempts (no conclusions)

### Capture Path

```
discovered in session → .claude/knowledge/ (hot experience)
                                ↓ validated multiple times
                         .claude/rules/ (hard rules)
```

## Context Management

### Compact Instructions

When context is compressed (/compact or auto-triggered), the following **must be preserved**:
- Current task goal and acceptance criteria
- Architecture decisions made and their rationale
- Key constraints from behavior boundaries
- Current worktree branch name and work progress
- Unresolved blocking issues

### HANDOFF Mode

When a long session is ending or context is near its limit, proactively write a `HANDOFF.md` to the project root:
```markdown
## Current Progress
## What Was Tried (worked / didn't work)
## Next Steps
## Key Decisions and Constraints
```
The next session only needs to read `HANDOFF.md` to continue. Delete the file when done.

### Context Hygiene

- Task switch → `/clear`
- Same task, new phase → `/compact`
- Long command output: pipe through `| head -30` to avoid context pollution

## Behavior Boundaries

### Always Do

- 修改 skill 只需要更新 `agents/.agents/skills/` 下的源文件（其他位置是 symlink）
- 使用 `stow --no-folding` 而非 `stow`（保持文件级 symlink）
- 修改配置后验证 symlink 是否正确指向

### Ask First

- 添加新的 stow 包（需要同步更新 `install.sh`）
- 修改 `dot-sync.sh` 或 `install.sh`（影响所有机器）
- 修改 `claude/.claude/settings.json` 中的 hooks 配置

### Never Do

- 把internal skill 推到 GitHub（必须在 `.gitignore` 中排除）
- 直接编辑 symlink 目标外的文件（编辑 `~/dotfiles/` 下的源文件即可）
- 在配置文件中硬编码机器特定的路径

## Progressive References

| 任务 | 参考文件 |
|------|----------|
| 添加/管理 skill | `agents/.agents/skills/` 下的 SKILL.md |
| Stow 部署机制 | `install.sh`、README.md "How Stow Works" 部分 |
| 同步机制 | `dot-sync.sh` |
| 通知配置 | `claude-notify.sh` |
| Shell 配置 | `zsh/.zshrc.shared` |
| Claude Code 设置 | `claude/.claude/settings.json` |

