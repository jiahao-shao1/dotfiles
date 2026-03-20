---
name: robbyctl
description: Manage GPU training jobs on AI Studio (蚂蚁集团 GPU 训练平台) via robbyctl CLI. Use when user asks about cluster status, GPU usage, job submission, job logs, queue position, or training job management. Triggers on "集群", "GPU", "训练任务", "robbyctl", "submit", "queue", "cluster", "H200", "robbys3", "overview".
---

# robbyctl — GPU Training Cluster CLI

`robbyctl` manages AI Studio training jobs. Before using it, activate the dedicated virtual environment:

```bash
source /ssd0/jhshao/.python/robbyctl/bin/activate
```

Binary at `/ssd0/jhshao/.python/robbyctl/bin/robbyctl`.

## Available Clusters

| Config | Cluster | GPU | Region |
|--------|---------|-----|--------|
| `job_config_vilab.yml` | vilab | A100 | cn-hangzhou |
| `job_config_robbywa180.yml` | robbywa180 | H20-3E | cn-hangzhou |
| `job_config_robbys3.yml` | robbys3 | H200 | cn-shanghai |
| `job_config_robbyh20b1.yml` | robbyh20b1 | H20 | cn-beijing |

Job configs at `/Users/lane/workspace/robbyctl/job_configs/`.

## Quick Reference

```bash
source /ssd0/jhshao/.python/robbyctl/bin/activate
RC=/ssd0/jhshao/.python/robbyctl/bin/robbyctl

# Cluster overview
$RC overview -c robbys3              # Resource dashboard
$RC list -c robbys3                  # All running + queued jobs
$RC list -c robbys3 --mine           # My jobs only
$RC list -c robbys3 --team VA        # Filter by team
$RC top -c robbys3                   # GPU usage ranking
$RC queue -c robbys3                 # Queue position + wait time

# Job lifecycle
$RC submit job_configs/job_config_robbys3.yml --dry-run  # Preview
$RC submit job_configs/job_config_robbys3.yml             # Submit
$RC status <RECORD_ID>               # Quick status
$RC describe <RECORD_ID>             # Full details + pods
$RC logs <RECORD_ID> --tail 50       # Last 50 lines
$RC logs <RECORD_ID> -f              # Follow mode
$RC pods <RECORD_ID>                 # Pod-level details
$RC events <RECORD_ID>               # Lifecycle timeline
$RC watch <RECORD_ID>                # Poll status changes
$RC ssh <RECORD_ID>                  # SSH into running pod
$RC stop <RECORD_ID>                 # Stop job (ownership check)
```

## Run Pod 日志查看（实时调试）

```bash
# 1. 先查看有哪些 pods
$RC pods <RECORD_ID>

# 2. 查看特定 pod 的日志（SLS 实时日志，推荐）
$RC logs <RECORD_ID> --pod master           # master pod 日志
$RC logs <RECORD_ID> --pod 0                # worker-0 日志
$RC logs <RECORD_ID> --pod worker-1         # worker-1 日志

# 3. 实时跟踪 run pod 日志（类似 tail -f）
$RC logs <RECORD_ID> --pod master -f        # 实时跟踪 master
$RC logs <RECORD_ID> --pod 0 -f             # 实时跟踪 worker-0
$RC logs <RECORD_ID> --pod master -f -n 100 # 先显示最后100行，再继续跟踪
```

**关键区别：**
- 不加 `--pod`：看 job-level 日志（聚合的，可能不完整）
- 加 `--pod`：看单个 pod 的实时 SLS 日志（完整、实时、支持 follow）

## Auth

Two auth systems required:

- **Cookie** (`~/.robbyctl/cookies.json`): 3 browser cookies (IAM_TOKEN, ctoken, ALIPAYJSESSIONID). Refresh with `robbyctl login`. Expires ~24h.
- **Token** (`~/.pypai/token.ini`): SDK token from AI Studio WebIDE.

If commands fail with auth errors, prompt user to refresh cookies via `robbyctl login`.

## Monitoring Patterns

For heartbeat/proactive monitoring:

```bash
# Check if any jobs are running
$RC list -c robbys3 --mine -o json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{len(d)} jobs')"

# Check cluster utilization
$RC overview -c robbys3

# Check queue depth
$RC queue -c robbys3
```

## Notes

- `list` uses Cookie API first, falls back to Token API
- `stop` enforces ownership — can only stop your own jobs
- `logs --pod` uses SLS API (concurrent pagination, fast for large logs)
- Submit requires internal PyPI packages (`aii-pypai`, `aistudio-common`)
- For detailed command docs, see `references/commands.md`
