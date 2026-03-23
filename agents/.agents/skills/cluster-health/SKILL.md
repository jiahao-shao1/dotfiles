---
name: cluster-health
description: 集群健康巡检。并行扫描所有节点的 GPU/磁盘/tmux 状态，汇总表格并推荐最空闲节点。触发词："cluster health"、"集群状态"、"节点状态"、"哪个节点空"、"最空闲节点"、"集群巡检"、"GPU 占用情况"。
---

# Cluster Health — 集群健康巡检

并行扫描所有集群节点，汇总 GPU / 磁盘 / tmux / 负载状态，推荐最空闲节点。

## 前置条件

- `robby-cluster-connect` 已配置，`mcp__cluster__remote_bash` 可用
- 节点列表从 `robby-cluster-connect` 的 `reference/context.local.md` 容器表读取

## Step 0: 读取节点列表

读取 `<robby-cluster-connect skill dir>/reference/context.local.md`，解析容器表中的所有节点名称（如 `sft`, `verl`, `node1`~`node8` 等）。

如果用户指定了 `--nodes node1,node3`，只扫描指定节点。

## Step 1: 并行探测

对每个节点，发起 **1 次** `remote_bash` 调用，用分隔符合并所有探测命令。

**在单条消息中并行调用所有节点的 remote_bash**，最大化并行度。

每节点执行的命令：

```bash
echo '===GPU==='; nvidia-smi --query-gpu=index,name,memory.used,memory.total,utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo 'NVIDIA_ERROR'; echo '===DISK==='; df -h /personal /ssd0 / 2>/dev/null | grep -vE 'tmpfs|Filesystem' ; echo '===TMUX==='; tmux list-sessions 2>/dev/null || echo 'NO_SESSIONS'; echo '===PROCS==='; nvidia-smi --query-compute-apps=pid,used_memory,name --format=csv,noheader,nounits 2>/dev/null || echo 'NO_PROCESSES'; echo '===LOAD==='; uptime
```

## Step 2: 解析输出

按 `===SECTION===` 分隔符切分每个节点的输出，提取：

### GPU
- 解析 CSV：`index, name, memory.used, memory.total, utilization.gpu, temperature.gpu`
- 空闲判定：`memory.used < 100` MiB **且** `utilization.gpu == 0`
- 计算：总卡数、空闲卡数、已用显存总和、总显存、平均利用率、最高温度

### 磁盘
- 解析 `df -h` 输出，提取 `/personal`、`/ssd0`、`/` 的 Used/Avail/Use%
- 标记 Use% > 90% 的为 WARNING

### tmux
- 解析 session 名和窗口数
- `NO_SESSIONS` 表示无活跃 session

### GPU 进程
- 解析 CSV：`pid, used_memory, name`
- 按显存降序排列

### 负载
- 从 `uptime` 提取 load average（1min, 5min, 15min）

## Step 3: 渲染报告

输出格式：

```markdown
## 集群健康报告 (YYYY-MM-DD HH:MM)

### GPU 概览

| 节点 | 总卡 | 空闲 | 已用显存 | 总显存 | 利用率 | 温度 | Load |
|------|------|------|---------|--------|--------|------|------|
| node1 | 8 | 3 | 120G | 640G | 45% | 72°C | 2.1 |
| node2 | 8 | 8 | 0G | 640G | 0% | 35°C | 0.0 |

### 磁盘

| 节点 | /personal | /ssd0 | / |
|------|-----------|-------|---|
| node1 | 1.2T/2T (60%) | 500G/1T (50%) | 20G/50G (40%) |
| node2 | 800G/2T (40%) | 200G/1T (20%) | 15G/50G (30%) |

### tmux Sessions

| 节点 | 数量 | 详情 |
|------|------|------|
| node1 | 2 | train_exp05 (3w), monitor (1w) |
| node2 | 0 | — |

### GPU 进程 (显存 > 1G)

| 节点 | PID | 显存 | 进程 |
|------|-----|------|------|
| node1 | 12345 | 70G | python train.py |

### 推荐

> **最空闲节点: node2** — 8 卡全空，/personal 60% 可用，无 tmux session，load 0.0
```

## 推荐算法

```
score = 空闲GPU卡数 × 100
      + /personal剩余百分比 × 1
      - 活跃tmux数 × 10
      - load_1min × 5
```

得分最高的节点为推荐节点。如果所有节点都满载（空闲卡 = 0），明确告知"无空闲节点"。

并列时优先选 /personal 剩余空间更大的。

## 异常处理

| 情况 | 处理 |
|------|------|
| `remote_bash` 超时 | 标记该节点为 `UNREACHABLE`，继续扫描其他节点 |
| `NVIDIA_ERROR` | GPU 信息标记 `N/A`，不参与推荐排序 |
| 磁盘 > 90% | 在磁盘列加 `⚠` 标记 |
| 所有节点满载 | 推荐部分输出"无空闲节点，建议等待或释放资源" |

## 用法示例

```
/cluster-health              # 扫描所有节点
/cluster-health node1,node3  # 只扫描指定节点
```

配合 `/loop` 可定时监控：
```
/loop 10m /cluster-health
```
