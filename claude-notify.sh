#!/bin/bash
# claude-notify.sh - Cross-platform notification for Claude Code hooks
# Usage: claude-notify.sh "message"

MSG="${1:-Claude Code}"

if [ "$(uname)" = "Darwin" ]; then
  osascript -e "display notification \"$MSG\" with title \"Claude Code\""
else
  curl -s -X POST \
    "https://api.telegram.org/botREDACTED_TELEGRAM_BOT_TOKEN/sendMessage" \
    -d "chat_id=REDACTED_TELEGRAM_CHAT_ID" \
    -d "text=$MSG" >/dev/null 2>&1
fi
