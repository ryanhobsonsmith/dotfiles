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

# Update window and session options if any state changed
if [ "$CHANGED" = true ]; then
  # Aggregate worst state from pane state files
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

  read -ra PANES <<< "$(tmux list-panes -t "$WINDOW_ID" -F '#{pane_id}' 2>/dev/null | tr '\n' ' ')"
  BEST=$(aggregate_state "${PANES[@]}")
  tmux set-option -qw -t "$WINDOW_ID" @claude_state "${BEST:-}" 2>/dev/null || true

  # Rebuild session bar cache with updated state
  ~/.tmux/scripts/session-list.sh >/dev/null 2>&1 && tmux refresh-client -S &
fi

exit 0
