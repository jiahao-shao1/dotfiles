#!/bin/bash
# init-research-profile.sh — 叠加 research profile
# 用法: bash init-research-profile.sh [项目根目录]
# 在 init-skeleton.sh 之后运行，添加研究项目特有的结构

set -euo pipefail

PROJECT_ROOT="${1:-.}"
cd "$PROJECT_ROOT"

CREATED=()
SKIPPED=()

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

ensure_dir() {
    mkdir -p "$1"
}

# ============================================================
# 1. 报告目录
# ============================================================
ensure_dir "docs/reports/weekly"
ensure_dir "docs/reports/worktree"
ensure_dir "docs/plans"

# ============================================================
# 2. 实验注册表
# ============================================================
create_file ".claude/knowledge/experiments.md" '# 实验注册表

记录所有实验的配置、路径和关键结果。

## 条目格式

```markdown
## 实验名称

- **日期**: YYYY-MM-DD ~ YYYY-MM-DD
- **配置**: 简述配置要点
- **路径**:
  - 集群: /path/on/cluster
  - OSS: oss://bucket/path
  - 本地: outputs/path
- **关键结果**:
  - 指标 1: 数值
  - 指标 2: 数值
- **结论**: 一句话总结
```

---

<!-- 在此追加实验条目 -->'

# ============================================================
# 3. 领域专家 Agent 骨架
# ============================================================
create_file ".claude/agents/domain-expert.md" '---
name: domain-expert
description: <!-- 填写：领域专长描述，如 "XX 框架集成和调试专家" -->
model: opus
tools:
  - Read
  - Grep
  - Glob
---

# Domain Expert

## 定位

<!-- 填写：这个 agent 的专长领域是什么 -->

## 何时使用

<!-- 填写：什么场景下应该调用这个 agent -->

## 工作方式

### 1. 接收问题

从上层工作流获取领域相关的技术问题。

### 2. 研究代码

重点关注的目录和文件：
<!-- 填写：列出这个 agent 应该重点研究的目录 -->

### 3. 输出建议

输出格式遵循 planner agent 的标准格式。

## 领域知识

<!-- 填写：关键的领域约束、接口约定、历史教训 -->'

# ============================================================
# 4. 在 CLAUDE.md 中追加 research 相关内容
# ============================================================
if [ -f "CLAUDE.md" ]; then
    # 检查是否已有 research profile 标记
    if ! grep -q "<!-- research-profile -->" "CLAUDE.md" 2>/dev/null; then
        cat >> "CLAUDE.md" << 'RESEARCH_EOF'

<!-- research-profile -->

## 扩展配置

详见 `.claude/agents/`、`.claude/skills/`、`.claude/rules/`、`.claude/knowledge/` 获取专项指导。

### Agents

| Agent | 用途 | Model | 触发场景 |
|-------|------|-------|---------|
| `planner` | 代码库研究 | opus | brainstorming/writing-plans 阶段 |
| `code-verifier` | ruff + pytest | haiku | 代码修改后、commit 前 |
| `domain-expert` | 领域专长 | opus | 涉及核心领域代码时 |

### Knowledge（经验积累）

| 文件 | 内容 |
|------|------|
| `experiments.md` | **实验注册表**：所有实验的配置、路径、关键结果 |
RESEARCH_EOF
        CREATED+=("CLAUDE.md (appended research profile)")
    else
        SKIPPED+=("CLAUDE.md (research profile already exists)")
    fi
fi

# ============================================================
# 输出摘要
# ============================================================
echo ""
echo "=========================================="
echo "  research profile 叠加完成"
echo "=========================================="
echo ""

if [ ${#CREATED[@]} -gt 0 ]; then
    echo "✓ 创建/修改了 ${#CREATED[@]} 个文件："
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
