#!/usr/bin/env bash
# Claude Code hook: tracks per-pane state for tmux status integration
# Writes state files, sets tmux window options (for window tabs), rebuilds session bar cache
set -euo pipefail

STATE_DIR="/tmp/claude-tmux"
mkdir -p "$STATE_DIR"

INPUT=$(cat)
EVENT=$(printf '%s' "$INPUT" | grep -o '"hook_event_name"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"')

PANE_ID="${TMUX_PANE:-unknown}"
STATE_FILE="${STATE_DIR}/pane-${PANE_ID//[^a-zA-Z0-9_%]/_}.state"

# Write per-pane state file
case "$EVENT" in
  UserPromptSubmit)  echo "working" > "$STATE_FILE" ;;
  PreToolUse)        echo "working" > "$STATE_FILE" ;;
  Stop)              echo "done" > "$STATE_FILE" ;;
  Notification)      echo "waiting" > "$STATE_FILE" ;;
  PermissionRequest) echo "waiting" > "$STATE_FILE" ;;
  SessionStart)      echo "idle" > "$STATE_FILE" ;;
  SessionEnd)        rm -f "$STATE_FILE" ;;
esac

# Aggregate worst state from a list of pane IDs
# Usage: aggregate_state pane_id [pane_id ...]
aggregate_state() {
  local best=""
  for pane in "$@"; do
    local file="${STATE_DIR}/pane-${pane//[^a-zA-Z0-9_%]/_}.state"
    [ -f "$file" ] || continue
    local state
    state=$(cat "$file" 2>/dev/null)
    case "$state" in
      waiting) best="waiting"; break ;;
      done)    [ "$best" != "waiting" ] && best="done" ;;
      working) [ "$best" != "waiting" ] && [ "$best" != "done" ] && best="working" ;;
      idle)    [ -z "$best" ] && best="idle" ;;
    esac
  done
  printf '%s' "$best"
}

# Update tmux window and session options
# Only set if value changed to avoid triggering unnecessary status refreshes
if [ "$PANE_ID" != "unknown" ] && command -v tmux >/dev/null 2>&1; then
  WINDOW_ID=$(tmux display-message -t "$PANE_ID" -p '#{window_id}' 2>/dev/null) || true

  # Update window-level @claude_state (used by catppuccin window tab conditionals)
  if [ -n "$WINDOW_ID" ]; then
    read -ra PANES <<< "$(tmux list-panes -t "$WINDOW_ID" -F '#{pane_id}' 2>/dev/null | tr '\n' ' ')"
    BEST=$(aggregate_state "${PANES[@]}")
    CURRENT=$(tmux show-option -qvw -t "$WINDOW_ID" @claude_state 2>/dev/null) || true
    [ "${BEST:-}" != "${CURRENT:-}" ] && tmux set-option -qw -t "$WINDOW_ID" @claude_state "${BEST:-}" 2>/dev/null || true
  fi

  # Rebuild session bar cache (sorted, with updated claude state icons)
  ~/.tmux/scripts/session-list.sh &
fi

exit 0
