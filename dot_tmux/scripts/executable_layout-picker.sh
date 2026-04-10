#!/usr/bin/env bash
# tmux layout picker using fzf

pane_count=$(tmux list-panes | wc -l | tr -d ' ')

entries="sidebar    [|][][]  1/3 + 2/3 split
even       [||][][]  50/50 split"

if [ "$pane_count" -gt 2 ]; then
  entries+="
tiled      [##][##]  grid"
fi

selected=$(printf '%s' "$entries" | fzf --height=~8 --layout=reverse --border=rounded \
  --prompt="layout> " --no-info \
  --color="bg+:#313244,fg+:#cdd6f4,hl:#f38ba8,hl+:#f38ba8,border:#89b4fa,prompt:#89b4fa" \
  | awk '{print $1}')

case "$selected" in
  sidebar)
    tmux set-window-option main-pane-width '33%'
    tmux select-layout main-vertical
    ;;
  even)
    tmux select-layout even-horizontal
    ;;
  tiled)
    tmux select-layout tiled
    ;;
esac
