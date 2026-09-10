# Workstation（vilab12）作为 Claude Code / Codex 主战场

## 2026-09-06: 把 CC / Codex 迁到 workstation，用 Remote Control 从 Mac / 手机接入

**Problem**: 本地公司 Mac 上跑 CC / Codex，换设备或离开电脑就断。workstation（Ubuntu 22.04，无 sudo）上只有 3 月的旧残留：claude 2.1.79、`~/.claude` / `~/.codex` 旧状态、两份 dotfiles、Go 时代的 robby-cluster-connect 拷贝、手写的 clash 配置。Mac 与 workstation 之间靠 8 条 mutagen session 同步 `.git`，commit 方向脆弱。

**Solution**（按依赖顺序）:

1. **代理**：`~/.config/mihomo/refresh.sh` 拉 VPS1 订阅 + 本地覆盖（仅 loopback 7890/7891、controller secret、prepend 30/8、11/8 与公司域名 DIRECT、rule-provider 走 PROXY 下载、过滤已退役 A6 网段），`-t` 校验后热重载；crontab `@reboot` + 每 6 小时 `reload`。内核 mihomo v1.19.30。Anthropic 直连 403 地区拦截，必须走这个代理。
2. **停 mutagen**：全部 `*-ws` 与已死集群 session terminate，仓库两端只走 git（ws 直推 GitHub / antcode，Mac `git pull`）。
3. **布局**：真身在 `/ssd1/jhshao/code/<repo>`（root 盘 85% 满、`/ssd0` 100% 满，`/ssd1` 3.2T 空闲）；`~/code -> /ssd1/jhshao/code`、`~/workspace -> ~/code`、`~/dotfiles -> ~/code/dotfiles`，MCP / venv / skill 链接全部经 `~/code` 解析，因此挪盘不用改注册。注意 CC / Codex 的 cwd 取物理路径，项目 trust 与会话历史按 `/ssd1/jhshao/code/<repo>` 记，挪盘后每个目录要重新过一次 trust；`~/.local/nodejs/current -> ~/.nvm/versions/node/v22.20.0` 让 statusLine 的 node 路径通用。旧目录归档为 `~/.claude.old-2026-03`、`~/.codex.old-2026-03`、`~/.agents/skills.old-2026-03`、`~/dotfiles.old-2026-03`、`~/workspace.old-2026-05`、`~/code/robby-cluster-connect.old-go`。
4. **CC**：`claude update`（经代理）→ 2.1.263；`~/.claude/settings.json` 手写 Linux 版（去掉 aivision `cchooks` 五个 hook，其余同 Mac，OTEL instance 改 ws 主机名）；CLAUDE.md / AGENTS.md / rules 用相对 symlink 指向 dotfiles；plugins 走 GitHub marketplace（sjh-skills / claude-hud；superpowers 与 baoyu-* / markitdown skill 同日在两台机器上一并移除，`install-skills.sh` 已同步删）；第三方 skills `scripts/install-skills.sh`；robby-skills + robby-cluster-connect `scripts/setup-skills.sh`；cluster 子 skill（cluster/gpu/run/sync/tail/deploy-agent）与 sjh-skills 各 skill 手动链进 `~/.agents/skills`（Codex 侧）。
5. **集群工具**：ssctl 用 `ssupgrade ensure` 升到 v1.16.13（linux-amd64）；robbyctl 用 `uv venv --seed --python 3.11` 建 venv 后跑 aistudio-jobs `setup.sh`（系统 python3 缺 `venv` 模块且无 sudo）；cluster MCP `MCP_SCOPE=user bash mcp-server/setup.sh` + `codex mcp add cluster`；`nodes.json` 只改 `ssctl_login.password_file` 路径，`vilab12` 节点经 `~/.ssh/config` 指向 127.0.0.1 自连。
6. **Codex**：nvm node 22 下 `npm i -g @openai/codex`；Mac 的 `~/.codex/auth.json` 拷过去即已登录；`config.toml` 精简版（去掉 ChatGPT.app 专属 node_repl / computer-use / notify）。
7. **Remote Control**：`.zshrc.shared` 加 `rc [name]`：在项目目录起一个带代理 env 的 detached tmux 跑 `claude remote-control`。前置：`claude auth login` 一次；每个目录先跑一次 `claude` 接受 trust。

**Lesson**:
- 订阅规则只有 `GEOIP,LAN,DIRECT`，公司 30/8、11/8 不是私网，会被送去 VPS；给 claude 进程注 `https_proxy` 时同时给 `no_proxy` 列公司域名，双保险。
- workstation 直连 GitHub release 资产只有 25KB/s，下载一律 `--proxy 127.0.0.1:7890 -C -`；npm / pypi / antcode / artifacts 直连正常。
- `ssh ws cat ~/.ssh/id_rsa.pub` 的 `~` 会被本地 zsh 先展开，要写成 `ssh ws 'cat ~/.ssh/id_rsa.pub'`。
- CC auto mode 的分类器会拦：远端写 crontab、追加 `authorized_keys`、tar 凭据文件、写可执行脚本、含 `approval_policy = "never"` 的配置。这些步骤留给用户手跑，agent 只做其余部分。
- `claude auth login` 在 ws 上必须先 `proxy`：最后一步 CLI 向 token 接口 POST，直连 403 `Request not allowed`，经代理才是正常的 400/200。登录后凭据在 `~/.claude/.credentials.json`。
- `claude remote-control` 要求目录已过 trust 对话框，且拒绝非交互接受（用 `~/.claude.json` 预置 `hasTrustDialogAccepted` 被 auto mode 分类器拦）。每个项目目录先 `cc-auto` 进去过一次 trust 再 `rc`。
- 挪 `~/code` 到别的盘：先 rsync 预拷，再停 rc 会话 → `rsync --delete` 增量 → `mv` 旧目录 + `ln -s` → 验证 → `rsync -n --delete` 对比无差异后再删旧目录。正在跑的 claude 进程 cwd 跟着旧 inode，不停会写进即将删除的目录。
- h200 上 mutagen 时代的 va2 副本没有 `.git` 且缺 `third_party/`（`.mutagenignore`）；转正规 clone：`git init` + `remote add` + `fetch` + `reset --mixed origin/main` + `git checkout -- .`。
- **skylark MCP 在 Linux 上可用**：`utoo-proxy` 有 Linux 版（官方 `setup.sh` 自动选 linux-x86），ws 无蚁家客户端要走 SDK 模式：MCP env 里带 `UTOO_USE_SDK=1`（`UTOO_SKIP_KEYRING=1` 一并带上保持一致），首次 `UTOO_USE_SDK=1 ~/.utoo-proxy/utoo-proxy login --timeout 900` 打印内网 OAuth 链接、进程侧轮询，不需要本地回调端口，在 Mac 浏览器打开即可；token 存 `~/.agent-client-sdk/utoo-proxy/tokens_secure.db`。**坑**：login 进程中途退出后再起会复用 `pkce_session.json` 里的旧 token（服务端已作废，授权页显示异常）；同时 `claude mcp get/list` 会拉起 utoo-proxy 实例一起轮询授权。修法：`pkill -x utoo-proxy`、把 `pkce_session.json` 挪走、只起一个 login。验证用 `utoo-proxy cli --mcp <url> --transport streamable skylark_user_info`。
- `claude-safe` 包装是 macOS codesign 手法，`.zshrc.shared` 里用 `CLAUDE_BIN` 变量按平台回退；替换路径字符串时别把刚插入的定义行也替换掉（发生过一次）。
- 未移植（无 Linux 版或无意义）：aivision `cchooks` / `cdxhooks`、agent-security plugin、`dws`（dingtalk skills）、chrome-devtools MCP。公司项目（va2）是否在无监管 hook 的 ws 上跑，是合规问题，单独决定。

**Files**: `zsh/.zshrc.shared`（`CLAUDE_BIN` 回退 + `rc()`）、workstation `~/.config/mihomo/refresh.sh`、`~/.claude/settings.json`、`~/.codex/config.toml`、`~/.config/robby-cluster/nodes.json`、`~/.ssh/config`、`~/.utoo-proxy/`；VPS 仓 `docs/knowledge/deployment.md` 2026-09-06 条
**Commit**: 未提交（在 workstation 上 commit）
