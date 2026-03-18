#!/bin/bash
# init-skeleton.sh — 为新项目生成 Claude Code 配置骨架
# 用法: bash init-skeleton.sh [项目根目录]
# 幂等：已存在的文件不覆盖

set -euo pipefail

PROJECT_ROOT="${1:-.}"
cd "$PROJECT_ROOT"

CREATED=()
SKIPPED=()

# 辅助函数：创建文件（不覆盖）
create_file() {
    local filepath="$1"
    local content="$2"
    mkdir -p "$(dirname "$filepath")"
    if [ -f "$filepath" ]; then
        SKIPPED+=("$filepath")
    else
        echo "$content" > "$filepath"
        CREATED+=("$filepath")
    fi
}

# 辅助函数：创建空目录
ensure_dir() {
    local dirpath="$1"
    mkdir -p "$dirpath"
}

# 获取项目名（从目录名推断）
PROJECT_NAME=$(basename "$(pwd)")

# ============================================================
# 1. 目录结构
# ============================================================
ensure_dir ".claude/rules"
ensure_dir ".claude/knowledge"
ensure_dir ".claude/hooks"
ensure_dir ".claude/agents"
ensure_dir ".claude/worktrees"
ensure_dir ".agents/skills"

# ============================================================
# 2. 通用 Hooks
# ============================================================
create_file ".claude/hooks/auto-format-python.sh" '#!/bin/bash
# Claude Code PostToolUse hook: 编辑 Python 文件后自动运行 ruff format
# 通过 $TOOL_INPUT 环境变量获取编辑的文件路径

FILE_PATH=$(echo "$TOOL_INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('"'"'file_path'"'"', '"'"''"'"'))
except:
    print('"'"''"'"')
" 2>/dev/null)

# 只处理 .py 文件，排除 third_party/
if [[ "$FILE_PATH" == *.py ]] && [[ "$FILE_PATH" != */third_party/* ]]; then
    # 运行 ruff format（静默，只在有问题时输出）
    ruff format "$FILE_PATH" --quiet 2>/dev/null

    # 运行 ruff check --fix（自动修复 import 排序等）
    OUTPUT=$(ruff check --fix "$FILE_PATH" 2>/dev/null)
    if [ -n "$OUTPUT" ]; then
        echo "$OUTPUT" | head -10
    fi
fi'

chmod +x ".claude/hooks/auto-format-python.sh" 2>/dev/null || true

# ============================================================
# 3. 通用 Agent 定义
# ============================================================
create_file ".claude/agents/code-verifier.md" '---
name: code-verifier
description: 代码质量检查。在代码修改后、commit 前主动运行 ruff lint/format 和 pytest，自动修复格式问题并报告结果。
model: haiku
tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# Code Verifier

## 何时使用

**主动使用**：用户完成代码修改、准备 commit 前。

## 检查流程

按顺序执行以下步骤：

### 1. 识别变更文件

```bash
git diff --name-only HEAD
git diff --name-only --cached
git ls-files --others --exclude-standard
```

仅检查 `.py` 文件，跳过 `third_party/`、`outputs/`、`__pycache__/`。

### 2. Ruff Lint + Format

```bash
ruff check --fix .
ruff format .
```

如果 ruff 不可用，回退到报告提示安装。

### 3. 运行测试

```bash
pytest tests/ -v --tb=short -q 2>&1 | tail -30
```

### 4. 报告结果

```
## 检查结果

| 检查项 | 状态 | 说明 |
|--------|------|------|
| Ruff Lint | PASS/FAIL/SKIP | 修复了 N 个问题 |
| Ruff Format | PASS/FAIL/SKIP | 格式化了 N 个文件 |
| Tests | PASS/FAIL/SKIP | N passed, M failed |
```

## 注意事项

- 不修改 `third_party/` 下的代码
- 测试失败时报告失败原因，不自行修复
- 如果 ruff 未安装，跳过 lint/format 步骤并提示安装'

create_file ".claude/agents/planner.md" '---
name: planner
description: 代码库研究。在 brainstorming 或 writing-plans 阶段需要深入了解代码结构时使用，研究代码后输出发现和建议。
model: opus
tools:
  - Read
  - Grep
  - Glob
---

# Planner（代码研究）

## 定位

本 agent 是 `/brainstorming` 和 `/writing-plans` 工作流的辅助工具，负责系统性研究代码库，输出发现供上层工作流使用。

**不是独立的规划器**——实现计划由 `/writing-plans` skill 负责。

## 何时使用

- `/brainstorming` 的 "Explore project context" 阶段需要深入代码研究
- `/writing-plans` 需要确认代码结构、找到可复用的模式
- 涉及 3+ 文件的任务需要先摸清代码关系

**不要用于**：单文件修改、已经清楚代码结构的任务。

## 工作方式

### 1. 接收研究问题

从 brainstorming 或 writing-plans 获取具体的研究问题。

### 2. 系统性搜索

按目录重点研究，使用 Glob、Grep、Read 工具。

### 3. 输出发现

```markdown
## 研究发现

### 相关文件
- `file_a.py:L42` — [做什么，为什么相关]

### 现有模式
- [可复用的模式]

### 建议
- [建议]

### 风险点
- [需要注意的约束]
```

## 注意事项

- 只读操作，不修改代码
- 引用具体的文件路径和行号'

# ============================================================
# 4. Settings.json（项目级）
# ============================================================
create_file ".claude/settings.json" '{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/auto-format-python.sh"
          }
        ]
      }
    ]
  }
}'

# ============================================================
# 5. CLAUDE.md 骨架
# ============================================================
create_file "CLAUDE.md" "# ${PROJECT_NAME} 项目说明

## 项目概述
<!-- init-project: 待填充 -->

## 目录结构和功能
<!-- init-project: 待填充 -->

## 开发工作流

本项目使用分阶段工作流：

\`\`\`
/brainstorming  →  /writing-plans  →  /subagent-driven-development  →  code-verifier
  探索想法            制定计划              执行计划                     质量检查
\`\`\`

### 阶段说明

| 场景 | 起始阶段 |
|------|---------|
| 新功能 / 架构变更 / 研究想法 | 从 \`/brainstorming\` 开始 |
| 需求已明确，需要实现计划 | 从 \`/writing-plans\` 开始 |
| 小修改（单文件、bug fix） | 直接修改 + \`code-verifier\` |

<!-- init-project: 如有项目特有的工作流阶段，在此补充 -->

## 开发指南
<!-- init-project: 待填充 -->

## 经验沉淀

当 session 中解决了非平凡问题（调试 bug、发现 workaround、设计 trade-off 等），**立即**将经验写入 \`.claude/knowledge/\` 对应的领域文件，不要等 session 结束。

### 写入规范

- **文件命名**：按领域主题，如 \`api-integration.md\`、\`deployment.md\`。遇到新领域直接建文件。
- **条目格式**：

\`\`\`markdown
## YYYY-MM-DD: 简短标题

**问题**: 遇到了什么
**解法**: 怎么解决的
**教训**: 以后应该注意什么
**文件**: 涉及的代码文件
**Commit**: 相关的 git commit hash
\`\`\`

### 什么该写

- 调试中发现的 bug 和根因
- 不明显的 workaround 或 API 行为
- 设计决策及其 trade-off
- 参数调优的经验

### 什么不该写

- 纯代码改动记录（由 git log 追踪）
- 文档中已有的内容
- 临时的探索性尝试（没有结论的）

### 沉淀路径

\`\`\`
session 中发现 → .claude/knowledge/ (热经验)
                         ↓ 经过多次验证
                  .claude/rules/ (硬性规则)
\`\`\`

## 上下文管理

### Compact Instructions

当上下文被压缩（/compact 或自动触发）时，**必须保留**以下信息：
- 当前任务目标和验收标准
- 已做出的架构决策及其理由
- 行为边界中的关键约束
- 当前 worktree 分支名和工作进度
- 尚未解决的阻塞问题

### HANDOFF 模式

长 session 即将结束或上下文接近上限时，主动写一份 \`HANDOFF.md\` 到项目根目录：
\`\`\`markdown
## 当前进度
## 尝试过什么（有效 / 无效）
## 下一步
## 关键决策和约束
\`\`\`
下一个 session 只需读 \`HANDOFF.md\` 即可接续工作。完成后删除该文件。

### 上下文卫生

- 任务切换 → \`/clear\`
- 同任务进入新阶段 → \`/compact\`
- 长命令输出用 \`| head -30\` 截断，避免污染上下文

## 行为边界

### Always Do

- 修改代码前先读相关文件，理解上下文
- 修改代码后运行相关单元测试
- 遵循同模块已有的代码风格和命名规范
<!-- init-project: 以下为示例，按项目需求修改 -->
<!-- - 跨模块修改确保配置一致性 -->
<!-- - API 调用包含超时保护和重试逻辑 -->

### Ask First

- 添加新的 Python 依赖
<!-- init-project: 以下为示例，按项目需求修改 -->
<!-- - 修改核心接口或配置结构 -->
<!-- - 运行 GPU 测试（先检查可用性） -->

### Never Do

- 硬编码 API key、路径或端点
- 直接修改 third_party/ 下的代码
<!-- init-project: 以下为示例，按项目需求修改 -->
<!-- - 修改不可变的接口签名 -->
<!-- - 猜测集群配置或硬件拓扑 -->

## 渐进式参考
<!-- init-project: 待填充 -->
"

# ============================================================
# 输出摘要
# ============================================================
echo ""
echo "=========================================="
echo "  init-skeleton 完成"
echo "=========================================="
echo ""

if [ ${#CREATED[@]} -gt 0 ]; then
    echo "✓ 创建了 ${#CREATED[@]} 个文件："
    for f in "${CREATED[@]}"; do
        echo "  + $f"
    done
fi

if [ ${#SKIPPED[@]} -gt 0 ]; then
    echo ""
    echo "⊘ 跳过了 ${#SKIPPED[@]} 个已存在的文件："
    for f in "${SKIPPED[@]}"; do
        echo "  - $f"
    done
fi

echo ""
echo "下一步：运行 Phase 2 交互式填充 CLAUDE.md"
