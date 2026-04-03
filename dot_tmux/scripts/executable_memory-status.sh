#!/bin/sh
# Output styled memory pressure segment for tmux status bar.
# Single #() call that outputs the full icon+text pill with dynamic icon color.
# Icon bg changes based on pressure level; text stays default module style.
#
# macOS: memory pressure from memory_pressure tool
# Linux: used memory % from /proc/meminfo
# Thresholds: @mem_medium_thresh (default 30), @mem_high_thresh (default 80)

get_percentage() {
  case "$(uname -s)" in
    Darwin)
      memory_pressure 2>/dev/null | awk '/System-wide memory free percentage:/ { print 100 - $NF }'
      ;;
    Linux)
      awk '/MemTotal/ { total = $2 } /MemAvailable/ { avail = $2 } END { printf "%.0f", (1 - avail / total) * 100 }' /proc/meminfo
      ;;
  esac
}

get_tmux_option() {
  val=$(tmux show -gqv "$1" 2>/dev/null)
  echo "${val:-$2}"
}

resolve_color() {
  tmux display -p "$1" 2>/dev/null
}

pct=$(get_percentage)

med_thresh=$(get_tmux_option @mem_medium_thresh 30)
high_thresh=$(get_tmux_option @mem_high_thresh 80)

if [ "$pct" -ge "$high_thresh" ]; then level=high
elif [ "$pct" -ge "$med_thresh" ]; then level=medium
else level=low; fi

case $level in
  high)   icon_bg=$(resolve_color "$(get_tmux_option @mem_high_icon_color '#{E:@thm_red}')") ;;
  medium) icon_bg=$(resolve_color "$(get_tmux_option @mem_medium_icon_color '#{E:@thm_yellow}')") ;;
  low)    icon_bg=$(resolve_color "$(get_tmux_option @mem_low_icon_color '#{E:@thm_blue}')") ;;
esac

icon_fg=$(resolve_color '#{E:@thm_crust}')
text_fg=$(resolve_color '#{E:@thm_fg}')
text_bg=$(resolve_color '#{E:@catppuccin_status_module_text_bg}')
lsep=$(get_tmux_option @catppuccin_status_left_separator '')
icon=$(get_tmux_option @catppuccin_mem_icon '󰍛 ')

printf '#[fg=%s]%s#[fg=%s,bg=%s]%s#[fg=%s,bg=%s] %d%%#[fg=%s]' \
  "$icon_bg" "$lsep" "$icon_fg" "$icon_bg" "$icon" "$text_fg" "$text_bg" "$pct" "$text_bg"
