#!/usr/bin/env bash
# Bridge Codex lifecycle hooks to cmux sidebar status and notifications.

raw_input="$(cat || true)"

if [[ -n "${CODEX_CMUX_HOOK_LOG:-}" ]]; then
  exec >>"${CODEX_CMUX_HOOK_LOG}" 2>&1
else
  exec >/dev/null 2>&1
fi

if [[ -z "${CMUX_WORKSPACE_ID:-}" && -z "${CMUX_SOCKET_PATH:-}" ]]; then
  exit 0
fi

if ! command -v cmux >/dev/null 2>&1; then
  exit 0
fi

event="$(
  HOOK_INPUT="${raw_input}" python3 - <<'PY'
import json
import os

raw = os.environ.get("HOOK_INPUT", "")
try:
    payload = json.loads(raw) if raw.strip() else {}
except Exception:
    payload = {}

print(payload.get("hook_event_name", ""))
PY
)"

status_key="${CODEX_CMUX_STATUS_KEY:-codex}"

case "${event}" in
  UserPromptSubmit)
    cmux set-status "${status_key}" "Running" --icon zap --color "#1E88E5" || true
    ;;
  Stop)
    cmux clear-status "${status_key}" || true
    cmux notify --title "Codex" --body "Finished" || true
    ;;
  SessionStart)
    cmux clear-status "${status_key}" || true
    ;;
esac

exit 0
