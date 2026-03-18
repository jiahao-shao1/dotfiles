# Agent 模板说明

init-skeleton.sh 生成的两个通用 agent 定义。

## code-verifier

**用途**：代码修改后、commit 前的自动质量检查。

**设计要点**：
- Model 用 haiku（快速、低成本，质量检查不需要强推理）
- 只给 Read/Grep/Glob/Bash 工具（不需要 Edit/Write）
- 检查流程固定：识别变更 → ruff lint/format → pytest → 报告
- 不自行修复测试失败，只报告

**定制建议**：
- 如果项目不用 Python，替换 ruff 为对应的 linter（如 eslint、clippy）
- 如果项目有特殊的测试命令，修改 pytest 部分
- 可以在"识别变更文件"步骤中添加项目特定的排除目录

## planner

**用途**：brainstorming 和 writing-plans 阶段的代码库研究辅助。

**设计要点**：
- Model 用 opus（需要深入理解代码，强推理能力）
- 只给 Read/Grep/Glob 工具（只读，不修改代码）
- 输出结构化的研究发现（相关文件、现有模式、建议、风险点）
- 不是独立的规划器，只是研究工具

**定制建议**：
- 在"系统性搜索"部分添加项目特定的重点目录
- 如果项目有领域专家 agent，在"注意事项"中添加分流逻辑

## 添加新 Agent 的模板

```markdown
---
name: {agent-name}
description: {一句话描述用途和触发场景}
model: {haiku|sonnet|opus}
tools:
  - Read
  - Grep
  - Glob
  # 按需添加：Bash, Edit, Write
---

# {Agent Name}

## 何时使用

{具体的使用场景列表}

## 工作方式

### 1. {步骤1}
### 2. {步骤2}
### 3. 输出结果

{输出格式模板}

## 注意事项

- {关键约束}
```

### Model 选择指南

| Model | 适用场景 | 成本 |
|-------|---------|------|
| haiku | 机械性任务（lint、格式化、简单检查） | 低 |
| sonnet | 中等复杂度（代码分析、模式识别） | 中 |
| opus | 深度研究（架构理解、复杂推理） | 高 |
