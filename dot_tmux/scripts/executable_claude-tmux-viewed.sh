#!/usr/bin/env bash
# Marks claude "done" states as "idle" when the user views a window
# Called by tmux after-select-window hook
set -euo pipefail

STATE_DIR="/tmp/claude-tmux"
[ -d "$STATE_DIR" ] || exit 0

WINDOW_ID=$(tmux display-message -p '#{window_id}' 2>/dev/null) || exit 0

CHANGED=false
for pane in $(tmux list-panes -t "$WINDOW_ID" -F '#{pane_id}' 2>/dev/null); do
  FILE="${STATE_DIR}/pane-${pane//[^a-zA-Z0-9_%]/_}.state"
  [ -f "$FILE" ] || continue
  STATE=$(cat "$FILE" 2>/dev/null)
  if [ "$STATE" = "done" ]; then
    echo "idle" > "$FILE"
    CHANGED=true
  fi
done

# Update window option if any state changed
if [ "$CHANGED" = true ]; then
  BEST=""
  for pane in $(tmux list-panes -t "$WINDOW_ID" -F '#{pane_id}' 2>/dev/null); do
    FILE="${STATE_DIR}/pane-${pane//[^a-zA-Z0-9_%]/_}.state"
    [ -f "$FILE" ] || continue
    STATE=$(cat "$FILE" 2>/dev/null)
    case "$STATE" in
      waiting) BEST="waiting"; break ;;
      done)    [ "$BEST" != "waiting" ] && BEST="done" ;;
      working) [ "$BEST" != "waiting" ] && [ "$BEST" != "done" ] && BEST="working" ;;
      idle)    [ -z "$BEST" ] && BEST="idle" ;;
    esac
  done
  tmux set-option -qw -t "$WINDOW_ID" @claude_state "${BEST:-}" 2>/dev/null || true
fi

exit 0
