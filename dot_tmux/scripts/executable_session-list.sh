#!/bin/sh
# Renders styled session list with claude status icons for tmux status bar
# Active session is lavender, inactive is muted. Claude icon color-coded by state.

active_fg="#b4befe"
inactive_fg="#6c7086"
bar_bg="#181825"
state_dir="/tmp/claude-tmux"

current_session=$(tmux display-message -p '#S')

result=""
for session in $(tmux list-sessions -F '#S'); do
  if [ "$session" = "$current_session" ]; then
    fg="$active_fg"
  else
    fg="$inactive_fg"
  fi

  # Find worst claude state across all panes in session
  claude_icon=""
  best_state=""
  for pane in $(tmux list-panes -s -t "$session" -F '#{pane_id}' 2>/dev/null); do
    safe_pane=$(printf '%s' "$pane" | tr -cd 'a-zA-Z0-9_%')
    file="${state_dir}/pane-${safe_pane}.state"
    [ -f "$file" ] || continue
    state=$(cat "$file" 2>/dev/null)
    case "$state" in
      waiting) best_state="waiting"; break ;;
      working) [ "$best_state" != "waiting" ] && best_state="working" ;;
      idle)    [ -z "$best_state" ] && best_state="idle" ;;
    esac
  done

  case "$best_state" in
    working) claude_icon=" #[fg=#fab387]󰚩" ;;
    waiting) claude_icon=" #[fg=#f38ba8]󰚩" ;;
    idle)    claude_icon=" #[fg=#6c7086]󰚩" ;;
  esac

  result="${result}#[fg=${fg},bg=${bar_bg}] ${session}${claude_icon} "
done

printf '%s' "$result"
