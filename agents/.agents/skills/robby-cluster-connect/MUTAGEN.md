# Mutagen File Sync through ssctl

Real-time file sync between your local machine and Robby (Lingjun) GPU cluster containers, using [Mutagen](https://mutagen.io).

**推荐模式**：`one-way-safe`（单向同步）。代码用本地→集群，outputs 用集群→本地。避免双向模式下删除不传播的问题。

## Why Mutagen?

Without Mutagen, you need to manually `git push` → `remote_bash git pull` for every code change. Mutagen provides **real-time file sync** — save a file locally and it appears on the cluster within seconds. No commits, no push/pull.

## The Challenge

ssctl's Go-based SSH proxy has two issues that break mutagen out of the box:

1. **Connections don't close** after commands finish — mutagen's SCP-based agent installation hangs forever
2. **stderr is merged into stdout** — mutagen agent's log messages corrupt the binary protocol handshake

This script solves both by pre-installing the agent via stdin pipe and wrapping it to redirect stderr.

## Quick Start

### Prerequisites

1. **mutagen** installed locally:
   ```bash
   brew install mutagen
   ```
2. **SSH tunnel** active (ssctl running, container accessible)
3. **SSH host** configured in `~/.ssh/config`, e.g.:
   ```
   Host h20
       HostName 127.0.0.1
       User root
       Port 8964
   ```

### Install & Sync

```
Usage: bash mutagen-setup.sh <ssh_host> <local_dir> <remote_dir> [session_name] [ignores...]

Arguments:
  ssh_host       SSH host alias from ~/.ssh/config (e.g. "h20")
  local_dir      Local project directory (e.g. "~/repo/my_project")
  remote_dir     Remote project directory (e.g. "/root/my_project")
  session_name   (Optional) Mutagen session name. Defaults to directory basename
  ignores        (Optional) Extra directories/patterns to ignore, space-separated
```

```bash
# Basic — sync a project with default settings
bash mutagen-setup.sh h20 ~/repo/hatssl /robby/share/3D/xuenan/hatssl

# With custom session name and extra ignores for large directories
bash mutagen-setup.sh h20 ~/repo/hatssl /robby/share/3D/xuenan/hatssl my-sync output wandb data logs
```

The script will:
1. Detect the remote platform architecture
2. Extract and upload the mutagen agent binary (via stdin pipe, bypassing SCP)
3. Verify the upload with checksum comparison
4. Create a stderr-redirecting wrapper (fixes the protocol corruption)
5. Create a mutagen sync session with sensible defaults

### Default Ignores

The following patterns are always ignored:

| Pattern | Reason |
|---------|--------|
| `.git` | Git history — sync code, not repo metadata |
| `__pycache__`, `*.pyc` | Python bytecode |
| `*.pt`, `*.pth`, `*.bin`, `*.safetensors`, `*.ckpt` | Model checkpoints (often GBs) |
| `.venv` | Virtual environments |
| `*.egg-info`, `node_modules` | Package metadata |
| `.DS_Store` | macOS artifacts |

Add extra ignores as positional arguments (e.g., `output wandb data logs`).

## Important Notes

### Symlinks

If your remote path is a symlink, **use the resolved path**:

```bash
# Check the real path
ssh h20 "readlink -f /root/hatssl"
# /robby/share/3D/xuenan/hatssl  ← use this

# Use the resolved path
bash mutagen-setup.sh h20 ~/repo/hatssl /robby/share/3D/xuenan/hatssl
```

### After Mutagen Upgrades

When you upgrade mutagen (`brew upgrade mutagen`), the agent version on the remote becomes stale. Simply re-run the script — it will detect the version mismatch and reinstall.

### Debugging

Agent logs are written to `/tmp/mutagen-agent.log` on the remote container:

```bash
ssh <host> "tail -20 /tmp/mutagen-agent.log"
```

### Coexistence with git sync

Mutagen and git sync can coexist. Mutagen handles real-time file sync for rapid iteration, while git remains the source of truth for versioning and collaboration. A typical workflow:

1. **Develop**: Edit locally, mutagen syncs to cluster instantly
2. **Train**: Run training via `remote_bash`
3. **Commit**: When ready, `git add && git commit && git push` as usual

## Managing Sync Sessions

```bash
# Check status
mutagen sync list

# Watch sync in real-time
mutagen sync monitor <session_name>

# Pause/resume
mutagen sync pause <session_name>
mutagen sync resume <session_name>

# Remove session
mutagen sync terminate <session_name>
```

## How It Works

### Normal Mutagen Flow (fails through ssctl)

```
mutagen sync create
  → SCP agent binary to remote      ← HANGS (ssctl doesn't close connections)
  → SSH exec agent                   ← Agent logs corrupt stdout (ssctl merges stderr)
  → Protocol handshake               ← FAILS (garbage bytes in stream)
```

### Our Workaround

```
mutagen-setup.sh
  → Upload agent via: cat binary | ssh host "cat > file"    ← Bypasses SCP
  → Wrapper script: exec agent-real "$@" 2>/dev/null         ← Isolates stderr
  → mutagen sync create                                      ← Works!
      → SSH exec wrapper → agent (clean stdout)
      → Magic number handshake ✓
      → Version handshake ✓
      → Bidirectional sync active
```

The key insight: mutagen's **long-lived agent communication** (stdin/stdout pipes) works perfectly through ssctl — the persistent connection is actually desired. Only the **installation** (SCP) and **stderr pollution** needed workarounds.

## Troubleshooting

### Daemon 卡死（connection timed out）

当 `mutagen sync list` 报 "connection timed out (is the daemon running?)" 时：

```bash
# 1. 杀掉所有 mutagen 进程
pkill -9 mutagen

# 2. 清理 socket 和 lock（关键步骤！）
rm -f ~/.mutagen/daemon/daemon.sock ~/.mutagen/daemon/daemon.lock

# 3. 重启 daemon
mutagen daemon start

# 4. 验证
mutagen sync list
```

**根因**：Daemon 通过 Unix socket 通信，连接超时只有 500ms。进程卡住后 socket/lock 文件残留，新 daemon 无法绑定。只杀进程不清理这两个文件会导致反复启动失败。

### 修改同步模式

Mutagen 不支持原地修改 session 模式，需要删除重建：

```bash
# 1. 记录当前配置（特别是 ignore 列表）
mutagen sync list <session_name> --long

# 2. 删除旧 session
mutagen sync terminate <session_name>

# 3. 重建（保持相同 name 和 ignore）
mutagen sync create --name=<session_name> --mode=one-way-safe \
  --ignore="*.pt" --ignore="*.pth" ... \
  <alpha_url> <beta_url>
```

### One-way-safe 冲突解决

`one-way-safe` 模式下，如果 beta 端已有与 alpha 不同的文件，会产生冲突。解决方法：

```bash
# 1. 删掉 beta 端冲突文件（让 alpha 版本同步过去）
rm <beta_side_conflict_files>

# 2. Reset session 清除冲突记录
mutagen sync reset <session_name>

# 3. Flush 触发同步
mutagen sync flush <session_name>
```
