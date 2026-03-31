#!/usr/bin/env bash
# Claude Code hook: tracks per-pane state for tmux status integration
# Writes state files (for session-list.sh) and sets tmux window options (for window tabs)
set -euo pipefail

STATE_DIR="/tmp/claude-tmux"
mkdir -p "$STATE_DIR"

INPUT=$(cat)
EVENT=$(printf '%s' "$INPUT" | grep -o '"hook_event_name"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"')

PANE_ID="${TMUX_PANE:-unknown}"
STATE_FILE="${STATE_DIR}/pane-${PANE_ID//[^a-zA-Z0-9_%]/_}.state"

# Write per-pane state file (used by session-list.sh)
case "$EVENT" in
  UserPromptSubmit)  echo "working" > "$STATE_FILE" ;;
  PreToolUse)        echo "working" > "$STATE_FILE" ;;
  Stop)              echo "idle" > "$STATE_FILE" ;;
  Notification)      echo "waiting" > "$STATE_FILE" ;;
  PermissionRequest) echo "waiting" > "$STATE_FILE" ;;
  SessionStart)      echo "idle" > "$STATE_FILE" ;;
  SessionEnd)        rm -f "$STATE_FILE" ;;
esac

# Update tmux window option (used by catppuccin window tabs)
# Aggregate the worst state across all panes in this window
if [ "$PANE_ID" != "unknown" ] && command -v tmux >/dev/null 2>&1; then
  WINDOW_ID=$(tmux display-message -t "$PANE_ID" -p '#{window_id}' 2>/dev/null) || true
  if [ -n "$WINDOW_ID" ]; then
    BEST=""
    for pane in $(tmux list-panes -t "$WINDOW_ID" -F '#{pane_id}' 2>/dev/null); do
      FILE="${STATE_DIR}/pane-${pane//[^a-zA-Z0-9_%]/_}.state"
      [ -f "$FILE" ] || continue
      STATE=$(cat "$FILE" 2>/dev/null)
      case "$STATE" in
        waiting) BEST="waiting"; break ;;
        working) [ "$BEST" != "waiting" ] && BEST="working" ;;
        idle)    [ -z "$BEST" ] && BEST="idle" ;;
      esac
    done
    tmux set-option -qw -t "$WINDOW_ID" @claude_state "${BEST:-}" 2>/dev/null || true
  fi
fi

exit 0
