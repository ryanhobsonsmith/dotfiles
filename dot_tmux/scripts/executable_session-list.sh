#!/bin/sh
# Rebuilds the session bar cache file for tmux status-format[0].
# Called by hooks (claude state changes, session lifecycle, session switch).
# Sorted alphabetically by name. Clickable via #[range=session|$id].

active_fg="#b4befe"
inactive_fg="#6c7086"
bar_bg="#181825"
state_dir="/tmp/claude-tmux"
cache_file="${state_dir}/session-bar"

mkdir -p "$state_dir"

# Sweep: remove state files for panes that no longer exist
for file in "$state_dir"/pane-*.state; do
  [ -f "$file" ] || continue
  pane_id=$(basename "$file" .state | sed 's/^pane-//')
  if ! tmux display-message -t "$pane_id" -p '' >/dev/null 2>/dev/null; then
    rm -f "$file"
  fi
done

result=""
for entry in $(tmux list-sessions -F '#{session_id}=#{session_name}' 2>/dev/null | sort -t= -k2); do
  id="${entry%%=*}"
  session="${entry#*=}"
  [ "$session" = "floating" ] && continue
  # Use tmux conditional so #S resolves per-client at render time
  fg="#{?#{==:#S,${session}},${active_fg},${inactive_fg}}"

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

printf '%s' "$result" > "$cache_file"
# Also store in tmux option for #{E:} expansion (per-client #S resolution)
tmux set -g @session_bar "$result" 2>/dev/null
exit 0
