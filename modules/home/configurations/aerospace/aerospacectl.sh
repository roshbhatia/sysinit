#!/bin/bash
# shellcheck disable=all
CACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/aerospace"
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

resize_all() {
  direction=$1
  [ -z "$direction" ] && handle_error "No direction"

  window_ids=$(aerospace list-windows --monitor mouse --format "%{window-id}" 2>/dev/null)
  [ -z "$window_ids" ] && handle_error "No windows under mouse monitor"

  if ! command -v displayplacer >/dev/null 2>&1; then
    handle_error "displayplacer not found"
  fi

  res=$(displayplacer list 2>/dev/null | awk '/Resolution:/ {print $2}' | head -n 1)
  [[ "$res" =~ ([0-9]+)x([0-9]+) ]] || handle_error "Could not parse screen resolution"

  screen_width="${BASH_REMATCH[1]}"
  screen_height="${BASH_REMATCH[2]}"

  presets=(50 33 67 25 75)
  last_state=0

  if [ -f "$RESIZE_STATE_FILE" ]; then
    last_dir=$(cut -d':' -f1 "$RESIZE_STATE_FILE")
    last_state=$(cut -d':' -f2 "$RESIZE_STATE_FILE")
    [ "$last_dir" != "$direction" ] && last_state=0
  fi

  percentage=${presets[$last_state]}
  [ -z "$percentage" ] && handle_error "Invalid percentage preset"

  if [[ "$direction" == "left" || "$direction" == "right" ]]; then
    pixels=$((screen_width * percentage / 100))
    cmd="resize width $pixels"
  elif [[ "$direction" == "up" || "$direction" == "down" ]]; then
    pixels=$((screen_height * percentage / 100))
    cmd="resize height $pixels"
  else
    handle_error "Invalid direction: $direction"
  fi

  while IFS= read -r id; do
    aerospace window "$id" "$cmd" || log "Failed to resize window $id"
  done <<<"$window_ids"

  next_state=$(((last_state + 1) % ${#presets[@]}))
  echo "$direction:$next_state:$(date +%s)" >"$RESIZE_STATE_FILE"
  log "$direction resize done to $percentage% ($pixels px); next state: $next_state"
}

show_help() {
  echo "Usage: aerospacectl [COMMAND]"
  echo ""
  echo "Commands:"
  echo "  left, right    Cycle horizontal window widths"
  echo "  up, down       Cycle vertical window heights"
  echo "  help           Show this help message"
}

case $1 in
left | right) resize_all "right" ;;
up | down) resize_all "down" ;;
help | --help | -h | *) show_help ;;
esac

exit 0

