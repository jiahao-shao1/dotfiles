# CLAUDE.md 各 Section 交互填充引导

Phase 2 中，逐个处理 `<!-- init-project: 待填充 -->` 占位符。每个 section 的处理流程：

```
读代码库（自动） → 生成草稿（自动） → AskUserQuestion 确认 → 写入 CLAUDE.md
```

用户回复 "skip" 可跳过任意 section，保留占位符。

---

## Section: 项目概述

### 自动探索

```
读取：README.md、pyproject.toml、package.json、Cargo.toml、go.mod
提取：项目名、描述、主要依赖
```

### AskUserQuestion

```
项目概述草稿如下：

---
{草稿内容}
---

这段描述准确吗？可以直接回车确认，或输入修改意见。回复 "skip" 跳过。
```

### 草稿模板

```markdown
**{项目名}** 是一个 {类型}，{一句话目标}。

核心思路：{技术方法}。

## 工作流程

1. {步骤1}
2. {步骤2}
3. ...
```

---

## Section: 目录结构和功能

### 自动探索

```
运行 ls 查看顶层目录
读取各子目录的 README.md 或 __init__.py docstring
识别：核心模块、第三方依赖、脚本、测试、文档
```

### AskUserQuestion

```
目录结构草稿如下：

---
{草稿内容：按模块列出目录和功能}
---

有遗漏或要调整的吗？回车确认 / 输入修改意见 / "skip" 跳过。
```

### 草稿模板

按以下分类组织：

```markdown
### 核心模块

#### `module_a/` - 功能描述
- 子模块说明
- 详见：`module_a/README.md`

### 第三方依赖

#### `third_party/xxx`
- 用途说明

### 其他目录

#### `scripts/` - 运行脚本
#### `tests/` - 单元测试
#### `docs/` - 文档
```

---

## Section: 开发工作流

### 自动探索

```
检测：.github/workflows/、Makefile、Justfile、scripts/、Dockerfile
检测：是否有 CI/CD、是否有 pre-commit hooks
```

### AskUserQuestion

```
检测到以下开发工具：{工具列表}

CLAUDE.md 中已写入默认的 brainstorming→plans→dev→verify 流程。
你的项目有额外的工作流阶段吗？（如部署、发布、数据处理等）

回车跳过 / 输入补充内容。
```

---

## Section: 开发指南

### 自动探索

```
检测：venv/conda 环境、.env 文件、Dockerfile、Makefile
检测：测试框架（pytest/jest/go test）、lint 工具（ruff/eslint）
读取：pyproject.toml 或 package.json 的 scripts 段
```

### AskUserQuestion

```
开发指南草稿如下：

---
### 环境配置

{检测到的环境配置步骤}

### 单元测试

{检测到的测试命令}

### {其他检测到的开发工具}
---

有什么要补充或修改的吗？
```

---

## Section: Always Do（项目特定条目）

### 自动探索

```
读取：.claude/rules/ 下已有的规则文件
检测：lint 配置（pyproject.toml [tool.ruff]、.eslintrc）
扫描：是否有多模块需要保持一致的配置
```

### AskUserQuestion

```
CLAUDE.md 中已写入 3 条通用的 Always Do 规则：
- 修改代码前先读相关文件
- 修改后运行相关单元测试
- 遵循同模块代码风格

你的项目还有哪些**跨模块一致性要求**？例如：
- 某些参数必须在多处保持一致
- API 调用必须包含重试逻辑
- 特定框架的约定必须遵守

回车跳过 / 输入补充条目。
```

---

## Section: Ask First

### 自动探索

```
扫描：核心接口定义（抽象类、协议、签名）
扫描：配置文件（yaml、toml、json）
扫描：third_party/ 依赖
```

### AskUserQuestion

```
已写入 1 条通用 Ask First 规则：
- 添加新的 Python 依赖

你的项目中，**哪些文件或目录修改前必须先确认**？例如：
- 核心配置文件
- 公共接口/协议定义
- 数据库 schema
- CI/CD 配置

回车跳过 / 输入补充条目。
```

---

## Section: Never Do

### 自动探索

```
检测：third_party/ 目录
检测：.env、credentials 等敏感文件
扫描：是否有"不可修改"的接口约定
```

### AskUserQuestion

```
已写入 2 条通用 Never Do 规则：
- 硬编码 API key、路径或端点
- 直接修改 third_party/ 下的代码

你的项目有哪些**绝对不能碰的约定**？例如：
- 不可修改的函数签名
- 不能猜测的外部配置
- 不能触碰的遗留代码

回车跳过 / 输入补充条目。
```

---

## Section: 渐进式参考

### 自动探索

```
扫描：docs/ 下的文档
列出：.claude/agents/ 中的 agent
列出：.agents/skills/ 中的 skill
```

### AskUserQuestion

```
根据代码库扫描，生成了以下参考表：

| 任务 | 参考文件 |
|------|---------|
{自动生成的映射}

还有需要补充的任务→参考文件映射吗？
```

---

## 完成后

所有 section 处理完毕后，输出汇总：

```
## CLAUDE.md 填充完成

| Section | 状态 |
|---------|------|
| 项目概述 | ✓ 已填充 |
| 目录结构 | ✓ 已填充 |
| 开发工作流 | ⊘ 跳过 |
| ...     | ... |

下一步：检查 CLAUDE.md 内容，然后 git add + commit。
```
