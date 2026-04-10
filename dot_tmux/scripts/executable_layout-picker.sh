#!/usr/bin/env bash
# tmux layout picker using fzf

layouts=(
  "even-horizontal"
  "main-vertical"
  "even-vertical"
  "main-horizontal"
  "tiled"
)

# Get current layout name for highlighting
current=$(tmux display-message -p '#{window_layout}' 2>/dev/null)
current_name=""
for name in "${layouts[@]}"; do
  # Apply each layout in a temp check isn't practical, so we skip exact matching
  :
done

# Build fzf input with preview descriptions
entries=""
for name in "${layouts[@]}"; do
  case "$name" in
    even-horizontal)  desc="[][][][]  side by side, equal width" ;;
    even-vertical)    desc="[=====]  stacked, equal height" ;;
    main-horizontal)  desc="[=====]  big top, small below" ;;
    main-vertical)    desc="[][][][]  small left, big right" ;;
    tiled)            desc="[##][##]  grid" ;;
  esac
  entries+="$name  $desc"$'\n'
done

selected=$(printf '%s' "$entries" | fzf --height=~10 --layout=reverse --border=rounded \
  --prompt="layout> " --no-info \
  --color="bg+:#313244,fg+:#cdd6f4,hl:#f38ba8,hl+:#f38ba8,border:#89b4fa,prompt:#89b4fa" \
  | awk '{print $1}')

[ -n "$selected" ] && tmux select-layout "$selected"
