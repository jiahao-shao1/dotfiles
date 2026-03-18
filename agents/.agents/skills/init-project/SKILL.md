---
name: init-project
description: 初始化新项目的 Claude Code 配置。用户说"初始化项目"、"init project"、"配置 Claude Code"时触发。
---

# Init Project

为新项目自动配置 Claude Code 最佳实践：目录骨架、通用 agent、hooks、CLAUDE.md。

## 执行骨架

1. **Phase 1: 生成骨架**（确定性脚本）
   → 运行 `scripts/init-skeleton.sh`，创建目录结构 + 通用文件
   → 输出创建了哪些文件

2. **Phase 2: 交互式填充 CLAUDE.md**（LLM + AskUserQuestion）
   → 逐 section 处理 `<!-- init-project: 待填充 -->` 占位符
   → 每个 section：读代码库 → 生成草稿 → AskUserQuestion 确认 → 写入
   → 用户可回复 "skip" 跳过某个 section
   → 详细引导模板见 `details/claude-md-sections.md`

3. **Phase 3: Profile 叠加**（可选）
   → AskUserQuestion: "要叠加额外 profile 吗？当前支持: research"
   → 选择 research → 运行 `scripts/init-research-profile.sh`
   → profile 说明见 `details/research-profile.md`

4. **输出摘要**
   → 列出所有生成/修改的文件
   → 提示下一步：检查内容、git add、开始开发

## Phase 2 各 Section 处理策略

| Section | 自动探索 | 问用户什么 |
|---------|---------|-----------|
| 项目概述 | 读 README、pyproject.toml、package.json | "一句话描述这个项目的核心目标？" |
| 目录结构和功能 | ls + 读关键文件 docstring | "以下目录结构对吗？有遗漏要调整的吗？" |
| 开发工作流 | 检测 CI、Makefile、scripts/ | "用默认的 brainstorming→plans→dev→verify 流程？" |
| 开发指南 | 检测 venv、.env、Dockerfile | "环境配置有什么特殊步骤？" |
| Always Do（项目特定） | 读已有 rules/、lint 配置 | "有哪些跨模块一致性要求？" |
| Ask First | 扫描核心文件（接口、配置） | "哪些文件/目录修改前必须先确认？" |
| Never Do | 检测 third_party/、.env | "有哪些绝对不能碰的约定？" |
| 渐进式参考 | 扫描 docs/、skills、agents | "还有需要补充的任务→参考文件映射吗？" |

## 约束

- **幂等**：已存在的文件不覆盖，只补缺
- **不自动 git add/commit**：生成后由用户决定
- **不修改已有内容**：只填充 `<!-- init-project: 待填充 -->` 占位符
- **脚本可独立运行**：`init-skeleton.sh` 和 `init-research-profile.sh` 可脱离 skill 单独执行

## 参考

- 骨架文件清单：`details/skeleton-manifest.md`
- CLAUDE.md 引导模板：`details/claude-md-sections.md`
- Agent 模板：`details/agent-templates.md`
- Research profile：`details/research-profile.md`
