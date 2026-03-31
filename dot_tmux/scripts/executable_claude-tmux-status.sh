#!/usr/bin/env bash
# Reads claude state files for a tmux window and outputs a color-coded icon
# Usage: claude-tmux-status.sh window <window_id>
# Colors: peach=working, red=waiting, grey=idle, nothing=no claude

STATE_DIR="/tmp/claude-tmux"
[ "$1" = "window" ] || exit 0
WINDOW_ID="${2:-}"
[ -n "$WINDOW_ID" ] || exit 0

PANES=$(tmux list-panes -t "$WINDOW_ID" -F '#{pane_id}' 2>/dev/null) || exit 0

BEST=""
for pane in $PANES; do
  FILE="${STATE_DIR}/pane-${pane//[^a-zA-Z0-9_%]/_}.state"
  [ -f "$FILE" ] || continue
  STATE=$(cat "$FILE" 2>/dev/null)
  case "$STATE" in
    waiting) BEST="waiting"; break ;;
    working) [ "$BEST" != "waiting" ] && BEST="working" ;;
    idle)    [ -z "$BEST" ] && BEST="idle" ;;
  esac
done

case "$BEST" in
  working) printf ' #[fg=#fab387]󰚩#[default]' ;;
  waiting) printf ' #[fg=#f38ba8]󰚩#[default]' ;;
  idle)    printf ' #[fg=#6c7086]󰚩#[default]' ;;
esac
