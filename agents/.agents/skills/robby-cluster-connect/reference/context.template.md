# 集群环境上下文

## 容器

统一使用 `mcp__cluster__remote_bash(node="<名称>", command="...")` 执行命令。

| 名称 | SSH 命令 | 用途 |
|------|---------|------|
| verl | `ssh -p 10025 127.0.0.1` | RL 训练 |
| sft | `ssh -p 10023 127.0.0.1` | SFT 训练、Benchmark |

默认 node 为第一个配置的节点。

## 共享存储

所有容器共享的持久化存储路径（NAS / SSD NAS / CPFS 等，不随容器释放而消失）。

| 路径 | 说明 |
|------|------|
| `/personal/` | 共享存储根目录 |
| `/personal/.mcp-agent/agent.py` | 集群端 Agent（所有容器共享） |

## 目录结构

| 路径 | 用途 | 权限 |
|------|------|------|
| `/personal/code/my_project` | 项目代码（git 仓库） | 读写 |
| `/personal/outputs` | 训练输出（日志、checkpoint） | 读写 |
| `/personal/data` | 数据集 | 读写 |
| `/robby/share/` | shared storage | **绝对不能删除或修改非自己的文件** |

## GPU 占用管理

集群 GPU 有 MFU 下限要求，空闲过久会被回收。

| 脚本 | 用途 | 何时调用 |
|------|------|---------|
| `/personal/code/start_gpu.sh` | 启动 GPU 占用 | 训练结束后、不跑程序时 |
| `/personal/code/stop_gpu.sh` | 停止 GPU 占用 | 训练启动前，释放显存 |

## 代码同步

- 推荐：Mutagen 实时同步（本地 → 共享存储，所有容器可见）
- 备选：本地 `git push` → 集群 `git pull`
- 集群无外网，但可通过内部源 pip install

## OSS 同步

集群输出通过 OSS 中转到本地，避免用 remote_bash 读大量文件（增量同步后本地读取快 ~20x）。

| 配置项 | 值 |
|--------|---|
| 上传脚本（集群执行） | `scripts/sync/cluster_upload_to_oss.sh` |
| 下载脚本（本地执行） | `scripts/sync/download_from_oss.sh` |
| 本地输出目录 | `outputs/`（项目根目录下） |
| 默认模式 | light（排除 *.pt, *.bin, *.safetensors, *.pth） |

前置条件：本地安装 ossutil64 并配好 OSS key。

## 其他备注

（自由填写：硬件信息、特殊限制等）
