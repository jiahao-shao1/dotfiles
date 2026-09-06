# 本地文件扫描范围

- 默认只在当前项目和任务明确涉及的目录中搜索。
- 禁止为了发现文件、Skill、配置或项目而递归扫描 `/`、`/Users` 或整个 `$HOME`。
- 查询本地 Skill 时，仅检查以下入口及当前项目对应目录：
  - `~/.claude/skills/`
  - `~/.agents/skills/`
  - `~/.codex/skills/`
  - `<repo>/.agents/skills/`
  - `<repo>/.claude/skills/`
- 如果已知入口不足，先说明还缺什么并向用户确认范围，不要自行扩大到全盘扫描。
