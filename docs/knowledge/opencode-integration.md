## 2026-04-13: Avoid Duplicating Claude Rules in OpenCode Instructions

**Problem**: `opencode/.config/opencode/opencode.json` injected `~/.claude/rules/*.md` through OpenCode `instructions` while oh-my-openagent also loaded `.claude/rules/` via its own compatibility layer. This duplicated rule text and broke conditional rule semantics such as `globs`.
**Solution**: Remove the `instructions` entry from `opencode.json` and keep only the `oh-my-openagent` plugin registration. Let oh-my-openagent own `.claude/rules/` loading.
**Lesson**: In OpenCode + oh-my-openagent setups, keep `opencode.json` minimal. Reserve OpenCode `instructions` for a tiny base context file, not the full Claude rules directory.
**Files**: opencode/.config/opencode/opencode.json
**Commit**: uncommitted (HEAD 0be0ef7)
