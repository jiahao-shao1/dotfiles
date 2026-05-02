
项目特定的 CC hooks（如 sync manifest 自动生成）必须放项目级 `.claude/settings.json`，不要放全局 `~/dotfiles/claude/.claude/settings.json`。

**Why:** 全局 hooks 对所有项目生效，项目特定的路径匹配和脚本在其他项目上下文中没有意义，还会污染其他项目的 hook 执行。

**How to apply:** 新建项目特定 hook 时，先检查项目是否已有 `.claude/settings.json` 和 `.claude/hooks/` 目录，优先复用已有结构。
