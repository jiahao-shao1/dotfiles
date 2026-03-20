---
name: sync-outputs
description: 从 OSS 同步集群实验结果到本地。列出 OSS 内容、增量下载实验输出、检查同步状态。用于 "同步结果"、"下载输出"、"查看 OSS"、"sync outputs"。
user_invocable: true
---

# Sync Outputs - 实验结果同步

从 OSS (`oss://antsys-vilab/sjh/outputs/`) 同步集群实验结果到本地 (`/data4/jhshao/outputs/`)。

## 工作流程

集群 `/personal/outputs/` → OSS `oss://antsys-vilab/sjh/outputs/` → 本地 `/data4/jhshao/outputs/`

## 执行步骤

### 1. 检查 OSS 上有什么

```bash
ossutil64 ls -d oss://antsys-vilab/sjh/outputs/
```

### 2. 检查本地已有什么

```bash
ls -la /data4/jhshao/outputs/
```

### 3. 对比差异并报告

比较 OSS 和本地的目录结构，告诉用户：
- OSS 上有哪些目录/文件
- 本地已有哪些
- 哪些是新增的需要下载

### 4. 执行增量下载

默认使用 `--light` 模式排除大文件（*.pt *.bin *.safetensors *.pth），只同步 logs 等轻量文件：

```bash
# 默认 light 模式
bash /ssd0/jhshao/agentic_umm/scripts/sync/download_from_oss.sh --light

# light + 指定子目录
bash /ssd0/jhshao/agentic_umm/scripts/sync/download_from_oss.sh --light <子目录>

# 用户明确要求下载 ckpt 时才用完整模式
bash /ssd0/jhshao/agentic_umm/scripts/sync/download_from_oss.sh <子目录>
```

### 5. 报告结果

下载完成后，报告：
- 下载了哪些新文件
- 总大小
- 耗时

## 注意事项

- 默认 `--light` 模式：排除 `*.pt *.bin *.safetensors *.pth`，只同步 logs、configs 等轻量文件
- 仅当用户明确要求下载 checkpoints/权重时，才使用不带 `--light` 的完整模式
- 使用 `-u` 参数进行增量同步，避免重复下载
- OSS bucket: `antsys-vilab`，路径前缀: `sjh/outputs/`
- 本地目标: `/data4/jhshao/outputs/`

## 集群端上传

如果用户需要先将集群结果上传到 OSS，提示他们：
1. SSH 到集群: `robbyctl ssh <job_id>`
2. 在集群上 clone 并运行: `cd oss_sync && bash run.sh`（默认 `--light` 定时同步）
3. 需要上传 ckpt: `bash cluster_upload_to_oss.sh <子目录>`（不加 `--light`）

集群 repo: `git@internal-git-host:shaojiahao.sjh/oss_sync.git`
