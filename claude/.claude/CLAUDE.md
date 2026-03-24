## 开发指南
### 单元测试

使用 `tests/` 下的单元测试来验证修改是否正确，提高 AI 的任务交付率。

### Skills 更新

每次更新 skill 只需要更新 `.agents` 下的，因为其他是软链接到它的。

## 重要提示

- **回答请务必使用中文**
- 修改代码后务必运行相关的单元测试

## Feedback

### internal Skill 部署

internal的 skills（如 robbyctl、sync-outputs）必须写到 `~/dotfiles/agents/.agents/skills/` 并在 `~/dotfiles/.gitignore` 中排除，不能推到 GitHub。

- Skill 源文件放 `~/dotfiles/agents/.agents/skills/<name>/SKILL.md`
- 在 `~/dotfiles/.gitignore` 添加 `agents/.agents/skills/<name>/` 和 `claude/.claude/skills/<name>`
- 在 `~/dotfiles/claude/.claude/skills/` 创建符号链接指向 `../../../agents/.agents/skills/<name>`
- 通过 `stow --no-folding agents && stow --no-folding claude` 部署
- 不要把internal skill 放在项目 `.agents/` 里

### work device绝对不能 push GitHub

work device（hostname `MacBook-Pro`）和 workstation（vilab12）上**绝对不能**直接 `git push` 到 GitHub（origin）。任何 repo 都必须先 push 到 internal-git，由用户自己在个人 Mac 上手动推到 GitHub。违反此规则会被security policy发现。

- 不要用 `git push origin`
- 不要用会自动 push origin 的脚本（如旧版 dot-sync）
- 包括 `git push github` 等任何指向 GitHub 的 remote
- force push 到 GitHub 也必须通过个人 Mac 执行
- 包括 workstation，network policy整个network到 github.com 的连接
- 不要在work device上设 cron 自动推 GitHub
- 不要在work device上用 `gh` CLI（会连 api.github.com）

### Worktree Merge 后不自动清理

Merge worktree 分支后，不要自动删除 worktree 和分支，除非用户明确要求清理。

### 网页抓取工具选择

按优先级逐级升级，优先用最轻量的工具：

| 优先级 | 工具 | 适用场景 | 命令 |
|--------|------|---------|------|
| 1 | **WebFetch** | 静态页面 | 内置工具 |
| 2 | **web-fetcher** | 公开 JS 页面（X、GitHub、V2EX） | `python3 .agents/skills/web-fetcher/scripts/fetch.py <url>` |
| 3 | **Playwright CLI** | 需登录/反爬（知乎、B站、Scholar Inbox） | `playwright-cli open --persistent <url>` |
| 4 | **Agent Reach** | Reddit、小红书、微博、YouTube/B站字幕 | `/agent-reach` skill |

不要默认用 Playwright CLI 读公开网页，浪费资源。web-fetcher 使用 Jina → defuddle → markdown.new 三级 fallback。