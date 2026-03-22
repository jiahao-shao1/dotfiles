---
name: robby-cluster-connect
description: 蚂蚁灵骏（Robby）集群操作。当用户提到集群、远程执行、GPU、训练、同步代码、mutagen 时使用。触发词包括但不限于："连集群"、"同步代码"、"GPU 占用"、"集群上跑"、"remote bash"、"robby"、"在服务器上"、"跑训练"、"看日志"、"tail log"、"mutagen"。即使用户没有明确提到集群，只要任务涉及远程执行或训练相关操作，也应该触发此 skill。
---

# Robby Cluster Connect

通过单个 MCP server 提供 `remote_bash` 工具（带 `node` 参数路由），在集群上执行命令。
使用持久 SSH 长连接 + 集群端 Agent 模式，命令延迟 ~0.1s（旧 sentinel 模式 ~1.5s，约 10x 加速）。

## Step 0: 检查配置

读取两层配置：

1. **用户级**：`reference/context.local.md`（集群/workstation/OSS 通用配置）
2. **项目级**：`<项目根>/.claude/cluster-context.md`（项目路径、mutagen session、同步脚本等）

- **两个都存在** → 合并上下文，跳到「核心操作」
- **用户级不存在** → 进入「首次配置」
- **用户级存在但项目级不存在** → 提示用户创建项目级配置（参考已有项目的 `.claude/cluster-context.md`）

## 首次配置

用 AskUserQuestion 收集信息，生成 `reference/context.local.md`。目标：2 轮交互完成。

### 第 1 轮：容器 + 项目路径（4 个问题）

同时问以下 4 个问题：

1. **容器数量**
   - header: "容器数量"
   - 选项: "1 个" / "2 个" / "3 个以上"

2. **第一个容器的 SSH 端口和名称**
   - header: "容器 1"
   - 选项带 preview 展示格式，用户通过 Other 自由输入
   - 选项示例: "10025 verl（RL 训练）" / "10023 sft（SFT/Benchmark）"
   - preview 示例: `端口: 10025\n名称: verl\nSSH:  ssh -p 10025 127.0.0.1\n用途: RL 训练`

3. **项目代码路径**
   - header: "项目路径"
   - 选项: "/personal/code/<项目名>（灵骏默认）" / "自定义路径"

4. **GPU 占用防回收**
   - header: "GPU 占用"
   - 选项: "需要（我有 start/stop 脚本，在 /personal/code/ 下）" / "需要（脚本在其他位置）" / "不需要"

如果用户选了 2 个以上容器，追加 1 轮问后续容器信息（同样用 preview 格式）。

### 第 2 轮：安全限制 + 共享存储 + 补充（2-3 个问题）

1. **共享存储安全限制**
   - header: "安全限制"
   - 选项: "/robby/share/ 不可删改（灵骏默认）" / "没有特殊限制" / "自定义"

2. **共享存储路径（用于 Agent 部署）**
   - header: "共享存储"
   - 说明：所有容器都能访问、不随容器释放而消失的挂载路径（如 NAS、SSD NAS、CPFS 等）
   - 选项: "/personal/（灵骏默认）" / "自定义路径"

3. **（条件）GPU 脚本路径**——仅当上轮选了"脚本在其他位置"时才问

### 生成配置 & 安装

根据交互收集的信息，执行以下步骤：

**Step 1: 生成配置文件**

参考 `reference/context.template.md` 格式，用用户回答填充，生成 `reference/context.local.md`。
注意在容器表中填入实际的节点名称和 SSH 命令，在共享存储部分填入 Agent 路径。

**Step 2: 构建 NODES JSON**

将所有容器的名称和 SSH 命令组成 JSON。例如用户输入了两个容器（sft 端口 10023、verl 端口 10025）：
```
NODES='{"sft":"ssh -p 10023 127.0.0.1","verl":"ssh -p 10025 127.0.0.1"}'
```

**Step 3: 安装 MCP server**

```bash
bash <skill_dir>/mcp-server/setup.sh "$NODES" <项目路径>
```

如果用户的共享存储路径不是默认的 `/personal/`，追加 agent_path 参数：
```bash
bash <skill_dir>/mcp-server/setup.sh "$NODES" <项目路径> <shared_storage>/.mcp-agent/agent.py
```

**Step 4: 提示重启 + 部署 Agent**

告诉用户：
1. 重启 Claude Code 以加载新的 MCP server
2. 重启后，运行以下命令部署集群端 Agent（只需做一次）：
   ```
   请说 "部署集群 Agent" 或 "deploy agent"，我会通过 remote_bash 自动完成
   ```

**Step 5: Agent 部署**（用户重启后触发）

当用户重启回来并请求部署 Agent 时：
1. 读取 `<skill_dir>/cluster-agent/agent.py` 的内容
2. 通过 `remote_bash` 写入集群共享存储：
   ```bash
   mkdir -p <shared_storage>/.mcp-agent
   cat > <shared_storage>/.mcp-agent/agent.py << 'AGENT_EOF'
   ... (agent.py 的完整内容)
   AGENT_EOF
   chmod +x <shared_storage>/.mcp-agent/agent.py
   python3 -c "import ast; ast.parse(open('<shared_storage>/.mcp-agent/agent.py').read()); print('syntax OK')"
   ```
3. 验证 Agent 可用：
   ```bash
   echo '{"type":"ping"}' | python3 <shared_storage>/.mcp-agent/agent.py
   ```
4. 提示用户再次重启 Claude Code，Agent 模式将自动启用

> 如果 Step 5 跳过，MCP server 仍然可用（自动降级为 sentinel 模式，~1.5s/命令）。
> Agent 部署后无需再次重启——下次 remote_bash 调用时会自动连接 Agent。

## 架构原则

- **代码编辑在本地**：Claude Code 原生工具（~0.5ms），远程 MCP 代理文件操作慢 ~2000x
- **远程只跑命令**：通过 `mcp__cluster__remote_bash(node="sft")` 执行
- **单个 MCP 管所有节点**：`node` 参数路由（sft/verl/...），扩展到 N 节点不增加 context 占用
- **Agent 模式优先**：共享存储上的 `agent.py` 通过 SSH 长连接通信，~0.1s/命令；不可用时自动降级为 sentinel 模式
- **代码同步**：可选 mutagen（实时同步）或 git（手动 push/pull）
- **读日志/结果在本地**：通过 mutagen 自动同步到本地 `outputs/`（推荐），或通过 OSS 中转。用原生 Read 工具读取（比 remote_bash cat 快 ~20x）

## 核心操作

以下操作中的路径均从 `reference/context.local.md` 读取，不要硬编码。

### 同步代码

**方式 1：Mutagen 实时同步**（推荐）

所有远程环境通过 mutagen 实时同步，保存即生效，无需手动操作。详见 `MUTAGEN.md`。

**方式 2：Git 手动同步**

```bash
# 本地
git add <files> && git commit -m "..." && git push

# 集群 (remote_bash)
cd <project_dir> && git pull
```

### GPU 占用管理（如果配置了）

```bash
# 释放 GPU（训练前）
bash <stop_gpu_script>

# 占用 GPU（训练后 / 空闲时）
bash <start_gpu_script>
```

### 启动训练

```bash
# remote_bash: 先停 GPU 占用（如果有），再启动训练
bash <stop_gpu_script> 2>/dev/null || true
cd <project_dir> && nohup <train_cmd> > <log_path> 2>&1 &
echo $!
```

### 检查训练状态

```bash
# remote_bash: 检查进程
ps -p <pid> -o pid,stat,etime --no-headers 2>/dev/null || echo "FINISHED"
tail -30 <log_path>

# 训练完成后重启 GPU 占用（如果有）
bash <start_gpu_script> 2>/dev/null || true
```

### 同步输出到本地（读日志/结果时优先使用）

当需要读取集群上的日志、评估结果等文件时，不要用 `remote_bash cat`——直接读本地文件。

**方式 1：Mutagen 实时同步**（推荐）

配置 mutagen one-way-safe session 将集群 outputs 自动同步到本地，排除 checkpoint 大文件。同步后直接用 Read 工具读取本地 `outputs/` 目录。

**方式 2：OSS 中转**（备选，适用于未配置 mutagen outputs 同步的项目）

路径和脚本从 `context.local.md` 的 OSS 同步配置读取。

```bash
# Step 1: 集群 → OSS（remote_bash 执行，排除大文件）
cd <project_dir> && bash <upload_script> [subdir]

# Step 2: OSS → 本地（本地 Bash 执行，排除大文件）
bash <download_script> [subdir]

# Step 3: 本地 Read 工具读取
# 文件现在在 <local_outputs_dir>/ 下，直接用 Read 工具
```

**注意**：默认排除 checkpoint 文件（*.pt, *.bin, *.safetensors, *.pth, *.ckpt, *.msgpack），避免撑爆本地存储。只在用户明确要求时才加 `--full`。

## 安全边界

- 从 `context.local.md` 读取共享存储限制并严格遵守——共享路径下的文件属于其他团队，误删可能导致他们的实验中断
- 集群无公网，但可通过内部源 pip install——不要尝试访问外部 URL（如 GitHub、PyPI 官方源）
- 不自动 push 到 master/main——避免未经 review 的代码影响团队其他成员
- **`pkill -f` 必须用方括号技巧**：`pkill -f "[s]glang.launch_server"` 而不是 `pkill -f "sglang.launch_server"`——因为 SSH 进程的命令行参数包含被 kill 的模式，`pkill -f` 会把 SSH 自身也杀掉，导致哨兵收不到，命令卡死。同理适用于所有 `pgrep -f`、`grep` 进程列表等操作
- **长驻进程必须后台化**：remote_bash 通过哨兵检测命令完成，如果进程不退出（如 sglang server、训练脚本），哨兵永远收不到，命令会卡死。必须用 `nohup ... &` 或 `tmux new-session -d`，且 `echo` 放在后台命令之后用 `;` 分隔：
  ```bash
  # 正确：nohup 后台 + echo 在外面
  nohup python -m sglang.launch_server ... > /tmp/log 2>&1 & echo "PID=$!"
  # 正确：tmux detach + echo 在外面
  tmux new-session -d -s sglang "python -m sglang.launch_server ..."; echo "started"
  # 错误：echo 在 tmux 内部的 && 链里，永远执行不到
  tmux new-session -d -s sglang "python ... && echo started"
  ```
