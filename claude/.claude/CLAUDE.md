## 开发指南
### 单元测试

使用 `tests/` 下的单元测试来验证修改是否正确，提高 AI 的任务交付率。

### Skills 更新

每次更新 skill 只需要更新 `.agents` 下的，因为其他是软链接到它的。

## 重要提示

- **回答请务必使用中文**
- 修改代码后务必运行相关的单元测试

## Feedback

### Internal Skill 部署

内部 skills 必须写到 `~/dotfiles/agents/.agents/skills/` 并在 `~/dotfiles/.gitignore` 中排除，不能推到 GitHub。

- Skill 源文件放 `~/dotfiles/agents/.agents/skills/<name>/SKILL.md`
- 在 `~/dotfiles/.gitignore` 添加 `agents/.agents/skills/<name>/` 和 `claude/.claude/skills/<name>`
- 在 `~/dotfiles/claude/.claude/skills/` 创建符号链接指向 `../../../agents/.agents/skills/<name>`
- 通过 `stow --no-folding agents && stow --no-folding claude` 部署

### Worktree Merge 后不自动清理

Merge worktree 分支后，不要自动删除 worktree 和分支，除非用户明确要求清理。

### 网页抓取工具选择

静态页面 → WebFetch | JS 页面/平台内容 → `/web-fetcher` | UI 操作 → Playwright CLI

不要默认用 Playwright CLI 读内容，优先用 web-fetcher（内含 OpenCLI fallback，覆盖知乎/X/Reddit 等）。
