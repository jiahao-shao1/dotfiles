# Research Profile 说明

research profile 在基础骨架之上，添加研究项目特有的结构。

## 额外生成的内容

### 目录

| 路径 | 用途 |
|------|------|
| `docs/reports/weekly/` | 周报输出目录 |
| `docs/reports/worktree/` | Worktree 工作报告目录 |
| `docs/plans/` | 设计文档和实现计划 |

### 文件

| 路径 | 内容 |
|------|------|
| `.claude/knowledge/experiments.md` | 实验注册表模板（日期、配置、三级路径、结果） |
| `.claude/agents/domain-expert.md` | 领域专家 agent 骨架（需用户填写专长） |

### CLAUDE.md 追加内容

在 CLAUDE.md 末尾追加"扩展配置" section：
- Agent 列表表格
- Knowledge 文件列表表格

## 实验注册表格式

每次开始新实验时，追加条目到 `.claude/knowledge/experiments.md`：

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

三级路径（集群/OSS/本地）用于追踪数据位置，方便同步和查找。

## 领域专家 Agent

`domain-expert.md` 是一个骨架文件，需要用户根据项目填写：

- `description`: 领域专长描述
- 何时使用: 触发场景
- 重点目录: 应该研究的代码位置
- 领域知识: 关键约束、接口约定、历史教训

通常一个研究项目会有 1-3 个领域专家 agent（如 rl-training-expert、data-pipeline-expert）。

## 未来可扩展的 Profile

| Profile | 用途 | 状态 |
|---------|------|------|
| research | 研究项目（实验、报告、领域专家） | 已实现 |
| web-app | Web 应用（组件结构、CI/CD） | 待开发 |
| data-pipeline | 数据管道（ETL、监控） | 待开发 |

新 profile 通过添加 `scripts/init-<profile>-profile.sh` + `details/<profile>-profile.md` 实现。
