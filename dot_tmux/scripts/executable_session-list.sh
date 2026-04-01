#!/bin/sh
# Renders styled session list with claude status icons for tmux status bar
# Sorted alphabetically by name. Clickable via #[range=session|$id].

active_fg="#b4befe"
inactive_fg="#6c7086"
bar_bg="#181825"
state_dir="/tmp/claude-tmux"

# Sweep: remove state files for panes that no longer exist
if [ -d "$state_dir" ]; then
  for file in "$state_dir"/pane-*.state; do
    [ -f "$file" ] || continue
    pane_id=$(basename "$file" .state | sed 's/^pane-//')
    if ! tmux display-message -t "$pane_id" -p '' 2>/dev/null; then
      rm -f "$file"
    fi
  done
fi

current_session=$(tmux display-message -p '#S')

result=""
for entry in $(tmux list-sessions -F '#{session_id}=#{session_name}' | sort -t= -k2); do
  id="${entry%%=*}"
  session="${entry#*=}"
  [ "$session" = "floating" ] && continue
  if [ "$session" = "$current_session" ]; then
    fg="$active_fg"
  else
    fg="$inactive_fg"
  fi

  # Find worst claude state across all panes in session
  claude_icon=""
  best_state=""
  for pane in $(tmux list-panes -s -t "$id" -F '#{pane_id}' 2>/dev/null); do
    safe_pane=$(printf '%s' "$pane" | tr -cd 'a-zA-Z0-9_%')
    file="${state_dir}/pane-${safe_pane}.state"
    [ -f "$file" ] || continue
    state=$(cat "$file" 2>/dev/null)
    case "$state" in
      waiting) best_state="waiting"; break ;;
      done)    [ "$best_state" != "waiting" ] && best_state="done" ;;
      working) [ "$best_state" != "waiting" ] && [ "$best_state" != "done" ] && best_state="working" ;;
      idle)    [ -z "$best_state" ] && best_state="idle" ;;
    esac
  done

  case "$best_state" in
    working) claude_icon="#[fg=#fab387]󰚩 " ;;
    done)    claude_icon="#[fg=#a6e3a1]󰚩 " ;;
    waiting) claude_icon="#[fg=#f38ba8]󰚩 " ;;
    idle)    claude_icon="#[fg=#6c7086]󰚩 " ;;
  esac

  result="${result}#[range=session|${id}]#[fg=${fg},bg=${bar_bg}] ${claude_icon}#[fg=${fg}]${session} #[norange]"
done

printf '%s' "$result"
