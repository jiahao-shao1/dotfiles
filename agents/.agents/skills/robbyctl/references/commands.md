# robbyctl Command Reference

Full command reference extracted from robbyctl README.

## list

List jobs on AI Studio. Cookie API priority (richer data), Token API fallback.

```
robbyctl list [-c CLUSTER] [--mine] [--user ID] [--team TEAM]
              [-s STATUS] [--all] [-n LIMIT] [--sort-by FIELD]
              [--created] [--team-gpu] [-o json|ids|names|tsv] [--less]
```

Flags:
- `-c, --cluster` — Cluster name (e.g. robbys3)
- `--mine` — My jobs only
- `--user ID` — Filter by user (employee number or nickname)
- `--team TEAM` — Filter by team (e.g. VA, VLA, 3D)
- `-s, --status` — Filter: running, queued, error, complete, deleted
- `-n, --limit` — Max results
- `--sort-by` — Sort by: gpu, time, name, wait, user, status
- `--team-gpu` — Show per-team GPU usage/quota column
- `-o` — Output format: json, ids, names, tsv

## describe

Full job details: metadata, resources, timeline, error message, pods summary.

```
robbyctl describe <RECORD_ID> [-o json] [--less]
```

## pods

Pod-level details: Name, Type, Status, GPU, CPU, Memory, Disk, Exit Code, OOM.

```
robbyctl pods <RECORD_ID> [-o json] [--less]
```

## logs

Job-level (Token API) or pod-level (SLS API) logs.

```
robbyctl logs <RECORD_ID> [--tail N] [-f] [--pod POD]
```

- `--pod POD` — Pod name: `master`, worker index (`0`, `1`), or full pod name
- `-f, --follow` — Live tail (poll every 5s, auto-stop when job ends)
- SLS performance: 52k lines in ~20s

## submit

Submit training job from YAML config.

```
robbyctl submit <CONFIG_FILE> [-u USER_CONFIG] [--remote-dir DIR]
                               [--dry-run] [-y] [--proxy]
```

User config search order: `-u` flag > `$ROBBYCTL_USER_CONFIG` > `./job_configs/user_config.yml` > `~/.robbyctl/user_config.yml`

## overview

Cluster GPU/CPU/memory usage, job counts, sub-group quotas.

```
robbyctl overview [-c CLUSTER] [-o json] [--less]
```

Without `-c`: lists all clusters. With `-c`: detailed view with member groups.

## top

GPU usage ranking, current user highlighted.

```
robbyctl top -c CLUSTER [--team TEAM] [--low] [--by cpu] [--less]
```

## queue

Queue position and wait time.

```
robbyctl queue -c CLUSTER [--low] [-o json] [--less]
```

## stop

Stop jobs. Enforces ownership check.

```
robbyctl stop <RECORD_ID> [-y]
robbyctl stop 123 456 789  # Multiple jobs
```

## ssh

SSH into running pod via ssctl.

```
robbyctl ssh <RECORD_ID>
```

## watch / status / events / config / groups / login

```
robbyctl watch <RECORD_ID> [-i INTERVAL]   # Poll status (default 30s)
robbyctl status <RECORD_ID> [-o json]       # Quick status check
robbyctl events <RECORD_ID> [-o json]       # Lifecycle timeline
robbyctl config set-cluster robbys3         # Set default cluster
robbyctl config show                        # Show all config
robbyctl groups -f robby                    # Search clusters
robbyctl login                              # Refresh cookies (interactive)
```

## Data Storage

| File | Description |
|------|-------------|
| `~/.pypai/token.ini` | SDK Token |
| `~/.robbyctl/cookies.json` | Browser SSO cookies |
| `~/.robbyctl/config.json` | Persistent config |
| `~/.robbyctl/groups_cache.json` | Cluster name→ID cache (1h TTL) |
| `~/.robbyctl/sls_cache.json` | SLS metadata cache (7-day TTL) |

## Environment Variables

| Variable | Description |
|----------|-------------|
| `ROBBYCTL_CLUSTER` | Default cluster name |
| `ROBBYCTL_USER_CONFIG` | Path to user_config.yml |
| `ROBBYCTL_GROUP_ID` | Default cluster ID (fallback) |
