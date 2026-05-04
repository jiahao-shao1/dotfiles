# Stow 与 Dotfiles 规则

## 编辑 stow 管理的文件

必须编辑 `~/dotfiles/` 下的源文件，不能编辑 symlink 目标路径。先 `readlink` 确认是否 symlink。

常见映射：
- `~/.config/ghostty/config` → `~/dotfiles/ghostty/.config/ghostty/config`
- `~/.zshrc.shared` → `~/dotfiles/zsh/.zshrc.shared`
- `~/.tmux.conf` → `~/dotfiles/tmux/.tmux.conf`

## 删目录前备份 gitignored 文件

`rm -rf` 含 `.git`/`.gitignore` 的目录前，先检查并备份 gitignored 的本地文件（如 `context.local.md`、`CONFIG.private.md`），这些文件无法通过 git 恢复。

## settings.json 管理

`~/.claude/settings.json` 由 CC Switch 管理，不纳入 stow。`~/dotfiles/claude/settings.template.json` 是新机器初始化模板，bootstrap 时自动复制。修改通用配置（plugins、hooks、marketplaces）时更新模板文件。
