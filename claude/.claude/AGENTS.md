## 重要提示

- **回答请务必使用中文**，简洁直接，不要废话
- 修改代码后务必运行相关的单元测试
- 不要频繁修改 `~/.claude/CLAUDE.md` / `AGENTS.md`——它们是 system prompt 的一部分，改一次所有项目 prompt cache 失效。工具策略 / 经验信息记到对应 rule 或 memory
- 在生成周报、slides 等需要署名的场景使用全名

## 核心提醒

### 蒸汽火车思维

CC 是蒸汽机，不要只用它造更好的蒸汽机零件（CC 工具/skill）。要找到这个时代的蒸汽火车——CC 让什么之前根本不可能的事情变成了可能？判断标准：它是否需要为它修铁轨（全新基础设施），而不是跑在现有的路上（现有工作流自动化）。当嘉豪开始造新 skill 时，提醒他想想：这是在给蒸汽机造零件，还是在修铁路。

## A6 海外集群 VPN 路由（按需手动）

A6 worker IP `202.159.0.0/16` 不在蚁家 VPN 默认路由表里。不加手工路由 → 流量走公网/Clash → `connection reset`。

**仅当 Mac 不在公司内网、已连接蚁家 VPN，且明确需要直连 A6 时手动运行**：`sudo ~/add_vpn_route.sh 202.159.0.0/16`（脚本自动检测 VPN 网关和接口）。不要配置自动运行任务。路由是临时的，断开 VPN / 重启 Mac 后自动清除；换 IDE 不需要重加（路由管网段，不管具体容器）。

## Feedback

### Worktree Merge 后不自动清理

Merge worktree 分支后，不要自动删除 worktree 和分支，除非用户明确要求清理。

## Context Loading

Claude Code 启动时自动加载 `~/.claude/rules/*.md`。**Codex/OpenAI agents 不会自动加载**，开始任务前先判断领域，再 Read 对应 rule。

| 任务领域 | 先读 |
|---|---|
| 用户身份 / 沟通偏好 | `~/.claude/rules/user-profile.md` |
| 跨项目映射 / 关键配置位置 / OSS / Notion config 路径 | `~/.claude/rules/personal-context.md` |
| Skill monorepo 加载方式 / 公司 → GitHub 同步流程 | `~/.claude/rules/skill-monorepos.md` |
| Mutagen 同步配置 / daemon 故障恢复 | `~/.claude/rules/mutagen-sync.md` |
| 创建项目特定 hooks / 修改 settings.json | `~/.claude/rules/project-hooks.md` |
| 编辑 stow 管理的 dotfiles / 删含 git 的目录 | `~/.claude/rules/stow-and-dotfiles.md` |
| 制作 HTML slides | `~/.claude/rules/slides.md` |

部分 rule 文件仅本地存在（含敏感内容，不入 dotfiles）。新机器若 Read 失败可跳过。
