## 2026-05-21: User-Level Bootstrap Without Homebrew

**Problem**: A fresh macOS machine did not have Homebrew, so `install.sh` would fail at the first `brew install stow` step before any dotfiles could be stowed.
**Solution**: Installed GNU Stow from the official source tarball into `~/.local`, installed shell-critical tools (`starship`, `zoxide`) into `~/.local/bin`, installed Node.js from the official macOS arm64 tarball into `~/.local/nodejs/current`, symlinked `node/npm/npx/claude` into `~/.local/bin`, then ran `stow --no-folding` and the existing skills/MCP setup scripts.
**Lesson**: On machines without Homebrew, keep the bootstrap path user-scoped: `~/.local/bin` is already prepended by `.zshrc.shared`, so the shell can work without system package manager changes. Run `stow -n --no-folding` first to catch conflicts before writing links.
**Files**: `scripts/bootstrap.sh`, `install.sh`, `zsh/.zshrc.shared`
**Commit**: N/A (session setup)
