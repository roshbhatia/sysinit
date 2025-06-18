#!/bin/bash
# shellcheck disable=all
CACHE_DIR="$XDG_DATA_HOME/aerospace"
RESIZE_STATE_FILE="$CACHE_DIR/window_state"
LOG_FILE="/tmp/log/aerospacectl.log"
mkdir -p "$CACHE_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [AEROSPACECTL] $1" | tee -a "$LOG_FILE" >&2
}

handle_error() {
  log "Error: $1"
  exit 1
}

smart_resize() {
  local direction=$1
  [ -z "$direction" ] && handle_error "No direction provided for smart resize"
  log "Starting smart resize: $direction"

  window_info=$(aerospace list-windows --workspace focused --format "%{window-id} | %{window-title}")
  window_id=$(echo "$window_info" | awk '{print $1}')
  [ -z "$window_id" ] && handle_error "Failed to retrieve window ID from focused workspace"
  log "Current window: $window_info"

  if command -v displayplacer >/dev/null 2>&1; then
    screen_info=$(displayplacer list 2>/dev/null | awk '/Resolution:/ {print $2}' | head -n 1)
    if [[ "$screen_info" =~ ([0-9]+)x([0-9]+) ]]; then
      screen_width="${BASH_REMATCH[1]}"
      screen_height="${BASH_REMATCH[2]}"
      log "Detected screen dimensions: ${screen_width}x${screen_height}"
    else
      handle_error "Failed to detect screen resolution"
    fi
  else
    handle_error "displayplacer command not found"
  fi

  presets=("1/2:50" "1/3:33" "2/3:67" "1/4:25" "3/4:75")
  last_state=0

  if [ -f "$RESIZE_STATE_FILE" ]; then
    last_direction=$(cut -d':' -f1 "$RESIZE_STATE_FILE")
    last_state=$(cut -d':' -f2 "$RESIZE_STATE_FILE")
    [ "$last_direction" != "$direction" ] && last_state=0
  fi

  current=${presets[$last_state]}
  [ -z "$current" ] && handle_error "Invalid state index: $last_state"

  desc=${current%:*}
  percentage=${current#*:}

  case $direction in
  left | right)
    if [ "$percentage" -eq 50 ]; then
      aerospace balance-sizes || handle_error "Failed to balance sizes"
      log "Balanced window sizes (50/50 split)"
    else
      pixels=$((screen_width * percentage / 100))
      aerospace resize width $pixels || handle_error "Failed to resize width"
      log "Set width to $desc ($percentage% = $pixels px)"
    fi
    ;;
  up | down)
    if [ "$percentage" -eq 50 ]; then
      aerospace balance-sizes || handle_error "Failed to balance sizes"
      log "Balanced window sizes (50/50 split)"
    else
      pixels=$((screen_height * percentage / 100))
      aerospace resize height $pixels || handle_error "Failed to resize height"
      log "Set height to $desc ($percentage% = $pixels px)"
    fi
    ;;
  *)
    handle_error "Invalid direction: $direction"
    ;;
  esac

  next_state=$(((last_state + 1) % ${#presets[@]}))
  echo "$direction:$next_state:$(date +%s)" >"$RESIZE_STATE_FILE"
  log "Saved state: $next_state"
  log "Resize completed"
}

show_help() {
  echo "Usage: aerospacectl [COMMAND]"
  echo ""
  echo "Commands:"
  echo "  [direction]   Resize the window (left, right, up, down)"
  echo "  help                       Show this help message"
}

case $1 in
right)
  shift
  smart_resize right
  ;;
left)
  shift
  smart_resize left
  ;;
up)
  shift
  smart_resize up
  ;;
down)
  shift
  smart_resize down
  ;;
help | --help | -h | *)
  show_help
  ;;
esac

exit 0
