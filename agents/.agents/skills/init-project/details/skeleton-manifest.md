# Skeleton Manifest

`init-skeleton.sh` 生成的完整文件清单。

## 目录

| 路径 | 用途 |
|------|------|
| `.claude/rules/` | 硬性规则（经验多次验证后提炼） |
| `.claude/knowledge/` | 热经验沉淀（调试发现、workaround） |
| `.claude/hooks/` | PostToolUse 等自动化钩子 |
| `.claude/agents/` | Agent 定义（领域专家、质量检查） |
| `.claude/worktrees/` | Worktree 追踪 |
| `.agents/skills/` | 项目级 Skill 定义 |

## 文件

| 路径 | 类型 | 内容 |
|------|------|------|
| `.claude/hooks/auto-format-python.sh` | Hook | 编辑 .py 后自动 ruff format + check --fix |
| `.claude/agents/code-verifier.md` | Agent | ruff lint/format + pytest，commit 前质量检查 |
| `.claude/agents/planner.md` | Agent | 代码库研究，brainstorming/writing-plans 辅助 |
| `.claude/settings.json` | Config | PostToolUse hooks 注册 |
| `CLAUDE.md` | 指南 | 项目说明骨架（含通用 section + 待填充占位符） |

## CLAUDE.md 骨架 Section 说明

| Section | 状态 | 说明 |
|---------|------|------|
| 项目概述 | 待填充 | Phase 2 交互填充 |
| 目录结构和功能 | 待填充 | Phase 2 交互填充 |
| 开发工作流 | 部分完成 | 通用流程已写入，项目特有部分待填充 |
| 开发指南 | 待填充 | Phase 2 交互填充 |
| 经验沉淀 | 已完成 | 通用模板，直接写入 |
| 上下文管理 | 已完成 | 通用模板，直接写入 |
| 行为边界 | 部分完成 | 通用条目已写入，项目特定条目待填充 |
| 渐进式参考 | 待填充 | Phase 2 交互填充 |

## 幂等行为

- 已存在的文件 → 跳过，不覆盖
- 已存在的目录 → 忽略
- 输出摘要区分"创建"和"跳过"
