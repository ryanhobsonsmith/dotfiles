#!/usr/bin/env bash
# Custom tmux sessionizer with Claude Code status icons
# Replaces tmux-sessionx. Bound to prefix+o via display-popup.
set -uo pipefail

STATE_DIR="/tmp/claude-tmux"
SEARCH_DIRS="$HOME/algebralabs $HOME/projects $HOME/chomp"
PINNED_DIRS="$HOME/.local/share/chezmoi $HOME/.config/nvim"

# --- helpers ---

claude_icon() {
  local session_id="$1" best=""
  for pane in $(tmux list-panes -s -t "$session_id" -F '#{pane_id}' 2>/dev/null); do
    local safe="${pane//[^a-zA-Z0-9_%]/_}"
    local file="${STATE_DIR}/pane-${safe}.state"
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
  case "$best" in
    working) printf '\033[38;2;250;179;135m󰚩\033[0m' ;;
    done)    printf '\033[38;2;166;227;161m󰚩\033[0m' ;;
    waiting) printf '\033[38;2;243;139;168m󰚩\033[0m' ;;
    idle)    printf '\033[38;2;108;112;134m󰚩\033[0m' ;;
    *)       printf ' ' ;;
  esac
}

list_entries() {
  # Active sessions (sorted, with claude icons)
  for entry in $(tmux list-sessions -F '#{session_id}=#{session_name}' 2>/dev/null | sort -t= -k2); do
    local sid="${entry%%=*}"
    local session="${entry#*=}"
    [ "$session" = "floating" ] && continue
    local icon
    icon=$(claude_icon "$sid")
    printf '%s %s\n' "$icon" "$session"
  done

  # Pinned directories (always shown unless already a session)
  printf '\033[38;2;108;112;134m── pinned ──\033[0m\n'
  for dir in $PINNED_DIRS; do
    [ -d "$dir" ] || continue
    local name
    name=$(basename "$dir")
    tmux has-session -t "=$name" 2>/dev/null && continue
    printf ' %s\n' "$dir"
  done

  # Separator
  printf '\033[38;2;108;112;134m── directories ──\033[0m\n'

  # Project directories not already open as sessions
  local dirs=""
  for search_dir in $SEARCH_DIRS; do
    [ -d "$search_dir" ] || continue
    dirs="$dirs $(find "$search_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)"
  done
  for dir in $(echo "$dirs" | tr ' ' '\n' | sort); do
    [ -z "$dir" ] && continue
    local name
    name=$(basename "$dir")
    tmux has-session -t "=$name" 2>/dev/null && continue
    printf ' %s\n' "$dir"
  done

  # Zoxide results (if available)
  if command -v zoxide >/dev/null 2>&1; then
    printf '\033[38;2;108;112;134m── recent (zoxide) ──\033[0m\n'
    zoxide query -l 2>/dev/null | head -15 | while IFS= read -r dir; do
      local name
      name=$(basename "$dir")
      tmux has-session -t "=$name" 2>/dev/null && continue
      printf ' %s\n' "$dir"
    done
  fi
}

preview_cmd() {
  local sel="$1"
  if tmux has-session -t "=$sel" 2>/dev/null; then
    tmux capture-pane -ep -t "$sel" 2>/dev/null
  elif [ -d "$sel" ]; then
    if command -v eza >/dev/null 2>&1; then
      eza --all --git --icons --color=always "$sel"
    else
      ls -la "$sel"
    fi
  else
    echo "$sel"
  fi
}

# Sub-command dispatch (called by fzf reload/preview bindings)
case "${1:-}" in
  --preview) preview_cmd "${2:-}"; exit 0 ;;
  --list)    list_entries; exit 0 ;;
esac

# --- main picker ---

SELF="$(realpath "$0")"

selected=$(list_entries | fzf --ansi --no-sort --reverse \
  --border-label ' sessions ' \
  --header '  enter: switch  ctrl-x: kill  ctrl-r: reload' \
  --preview "$SELF --preview {2..}" \
  --preview-window right:50% \
  --bind "ctrl-x:execute-silent(tmux kill-session -t {2..} 2>/dev/null)+reload($SELF --list)" \
  --bind "ctrl-r:reload($SELF --list)" \
  | sed 's/^[[:space:]]*//' | sed 's/^[^ ]* //')

[ -z "$selected" ] && exit 0

# Skip separator lines
case "$selected" in
  ──*) exit 0 ;;
esac

# Connect to existing session or create new one
if tmux has-session -t "=$selected" 2>/dev/null; then
  tmux switch-client -t "=$selected"
elif [ -d "$selected" ]; then
  dir="$(cd "$selected" && pwd)"
  session_name="$(basename "$dir")"
  sh="$(basename "$SHELL")"

  if ! tmux has-session -t "=$session_name" 2>/dev/null; then
    tmux new-session -d -s "$session_name" -c "$dir" -n "zsh"
    tmux new-window -t "$session_name:" -c "$dir" -n "claude" "$sh -ic 'claude; exec $sh'"
    tmux select-window -t "$session_name:zsh"
  fi
  tmux switch-client -t "=$session_name"
fi
