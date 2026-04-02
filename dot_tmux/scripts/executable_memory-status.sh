#!/bin/sh
# Output memory usage/pressure percentage, OS-aware.
# macOS: memory pressure from memory_pressure tool
# Linux: used memory % from /proc/meminfo
#
# Args:
#   --fg  Output hex fg color based on thresholds
#   --bg  Output hex bg color based on thresholds
#   (none) Output percentage value
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

case "${1:-}" in
  --fg|--bg)
    med_thresh=$(get_tmux_option @mem_medium_thresh 30)
    high_thresh=$(get_tmux_option @mem_high_thresh 80)

    if [ "$pct" -ge "$high_thresh" ]; then level=high
    elif [ "$pct" -ge "$med_thresh" ]; then level=medium
    else level=low; fi

    if [ "$1" = "--fg" ]; then
      case $level in
        high)   resolve_color "$(get_tmux_option @mem_high_fg_color '#{E:@thm_crust}')" ;;
        medium) resolve_color "$(get_tmux_option @mem_medium_fg_color '#{E:@thm_fg}')" ;;
        low)    resolve_color "$(get_tmux_option @mem_low_fg_color '#{E:@thm_fg}')" ;;
      esac
    else
      case $level in
        high)   resolve_color "$(get_tmux_option @mem_high_bg_color '#{E:@thm_red}')" ;;
        medium) resolve_color "$(get_tmux_option @mem_medium_bg_color '#{E:@catppuccin_status_module_text_bg}')" ;;
        low)    resolve_color "$(get_tmux_option @mem_low_bg_color '#{E:@catppuccin_status_module_text_bg}')" ;;
      esac
    fi
    ;;
  *)
    printf "%d%%" "$pct"
    ;;
esac
