#!/bin/bash
# claude-notify.sh - Cross-platform notification for Claude Code hooks
# Usage: claude-notify.sh "message"

MSG="${1:-Claude Code}"

if [ "$(uname)" = "Darwin" ]; then
  if command -v cmux &>/dev/null && [ -n "$CMUX_SURFACE_ID" ]; then
    # cmux 环境：只用 cmux notify，不发系统通知（避免重复）
    cmux notify "Claude Code" "$MSG" 2>/dev/null
  else
    osascript -e "display notification \"$MSG\" with title \"Claude Code\""
  fi
else
  curl -s -X POST \
    "https://api.telegram.org/botREDACTED_TELEGRAM_BOT_TOKEN/sendMessage" \
    -d "chat_id=REDACTED_TELEGRAM_CHAT_ID" \
    -d "text=$MSG" >/dev/null 2>&1
fi
