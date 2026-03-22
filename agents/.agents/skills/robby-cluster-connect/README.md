# Robby Cluster Connect

![Version](https://img.shields.io/badge/version-0.2.0-blue)

English | [中文](README.zh-CN.md)

> A Claude Code skill for operating GPU clusters — edit code locally, run commands remotely with ~0.1s latency via persistent SSH agent connections.

## Install

```bash
npx skills add git@github.com:jiahao-shao1/robby-cluster-connect.git
```

Restart Claude Code after installing, then say "连集群" to start. Claude will guide you through the setup automatically on first use (containers, paths, MCP server installation).

## Architecture

![Architecture](docs/arch-en.jpg)

**Two execution modes** — agent mode is ~10x faster, sentinel mode is the automatic fallback:

| Mode | Latency | How it works |
|------|---------|-------------|
| **Agent mode** | ~0.1s | Persistent SSH connection → cluster-side `agent.py` → JSON-Lines protocol |
| **Sentinel mode** | ~1.5s | Per-command SSH → sentinel pattern detection → `proc.kill()` |

- **Code editing**: Local Claude Code native tools (~0.5ms)
- **Code sync**: Mutagen real-time sync (recommended, see [MUTAGEN.md](MUTAGEN.md)) or git push/pull
- **Remote execution**: `remote_bash(node="sft", command="...")` — single MCP, multi-node routing

## Why This Exists

GPU clusters often sit behind SSH proxies that don't close connections after commands finish, so plain `ssh host "cmd"` hangs forever. This skill works around this with sentinel-based detection, and further accelerates it with a persistent agent connection.

## How It Works

### Agent Mode (fast, ~0.1s)

```
MCP Server                          Cluster Container
┌──────────┐   SSH long connection  ┌────────────┐
│ AgentConn│── stdin: JSON req ───→│ agent.py   │
│ Pool     │←─ stdout: JSON resp ──│ subprocess │
│ (per     │                       │ .run(cmd)  │
│  node)   │                       └────────────┘
└──────────┘
```

One SSH connection per node, kept alive with `ServerAliveInterval`. Commands sent as JSON-Lines, results returned immediately.

### Sentinel Mode (fallback, ~1.5s)

```
remote_bash("nvidia-smi")

→ ssh -tt -p 10025 127.0.0.1 'nvidia-smi 2>&1; echo "___MCP_EXIT_${?}___"'

stdout:
  | NVIDIA H20 ...
  ___MCP_EXIT_0___     ← sentinel detected

→ proc.kill()          ← force-kill SSH (proxy won't close it)
→ return clean output
```

Used automatically when the agent is not available.

## File Structure

```
robby-cluster-connect/
├── SKILL.md                          # Skill instructions for Claude
├── cluster-agent/
│   └── agent.py                      # Cluster-side agent (zero deps, ~100 lines)
├── mcp-server/
│   ├── mcp_remote_server.py          # MCP server with agent mode + sentinel fallback
│   ├── pyproject.toml                # Dependencies: mcp>=1.25
│   └── setup.sh                      # One-command install (supports multi-node JSON)
├── reference/
│   ├── context.template.md           # Configuration template
│   └── context.local.md              # Your config (gitignored, auto-generated)
├── MUTAGEN.md                        # Mutagen real-time sync guide
└── docs/
    └── arch-en.jpg                   # Architecture diagram
```

## Configuration

The skill uses a two-layer configuration:

1. **User-level** (`reference/context.local.md`): Cluster containers, SSH ports, workstation, GPU scripts — shared across all projects
2. **Project-level** (`<project>/.claude/cluster-context.md`): Project paths, mutagen sessions, sync scripts — specific to each project

Both are auto-generated through interactive setup on first use.

## Acknowledgements

Heavily inspired by [claude-code-local-for-vscode](https://github.com/justimyhxu/claude-code-local-for-vscode).

Thanks to [@cherubicXN](https://github.com/cherubicXN) for the implementation of Mutagen-based local-cluster real-time sync.

## License

MIT
