#!/bin/bash
# aerospacectl - Unified script for managing aerospace display cache and smart-resize functionality

CACHE_DIR="$XDG_DATA_HOME/aerospace"
DISPLAY_CACHE="$CACHE_DIR/displaycache"
DISPLAY_INFO="$CACHE_DIR/display_info"
RESIZE_STATE_FILE="$CACHE_DIR/window_state"
mkdir -p "$CACHE_DIR"

log() {
  echo "[AEROSPACECTL] $1" >&2
}

handle_error() {
  log "Error: $1"
  exit 1
}

update_display_cache() {
  log "Updating display cache"

  # Clear existing files
  rm -f "$DISPLAY_INFO" "$DISPLAY_CACHE"

  # Get display information
  if command -v aerospace >/dev/null 2>&1; then
    display_info=$(aerospace list-monitors 2>/dev/null | while read -r line; do
      id=$(echo "$line" | cut -d'|' -f1)
      name=$(echo "$line" | cut -d'|' -f2 | tr -d ' ' | base64)
      echo "$id | $name"
    done)
    log "Retrieved data from aerospace"
  else
    handle_error "Aerospace command not found"
  fi

  # Write to cache
  if [ ! -z "$display_info" ]; then
    echo "$display_info" > "$DISPLAY_CACHE"
    log "Display cache updated successfully"
  else
    handle_error "Failed to retrieve display information"
  fi

  # Detect screen resolution
  if command -v screenresolution &>/dev/null; then
    log "Attempting to retrieve real resolution via screenresolution"
    FOCUSED_MONITOR_INFO=$(aerospace list-monitors --focused --json 2>/dev/null)
    FOCUSED_MONITOR_ID=$(echo "$FOCUSED_MONITOR_INFO" | jq -r '.[0]["monitor-id"]')
    if [[ ! -z "$FOCUSED_MONITOR_ID" && "$FOCUSED_MONITOR_ID" != "null" ]]; then
      SCREEN_INDEX=$((FOCUSED_MONITOR_ID - 1))
      SCREEN_INFO=$(screenresolution get 2>/dev/null | grep "Display $SCREEN_INDEX:" | grep -oE '[0-9]+x[0-9]+')
      if [ ! -z "$SCREEN_INFO" ]; then
        monitor_name=$(echo "$FOCUSED_MONITOR_INFO" | jq -r '.[0]["monitor-name"]' | tr -d ' ' | base64)
        echo "\"$monitor_name\",\"$SCREEN_INFO\"" > "$DISPLAY_INFO"
        log "Retrieved resolution $SCREEN_INFO for monitor $monitor_name"
        return
      fi
    fi
  fi

  handle_error "Failed to update display information"
}

smart_resize() {
  local direction=$1
  [ -z "$direction" ] && handle_error "No direction provided for smart resize"
  log "Starting smart resize: $direction"

  # Get focused window info
  window_info=$(aerospace list-windows --focused --format "%{window-id} | %{window-title}")
  window_id=$(echo "$window_info" | awk '{print $1}')
  [ -z "$window_id" ] && handle_error "Failed to retrieve focused window ID"
  log "Current window: $window_info"

  # Screen dimensions
  screen_width=2056
  screen_height=1329
  if command -v screenresolution &>/dev/null; then
    screen_info=$(screenresolution get 2>/dev/null)
    if [[ "$screen_info" =~ ([0-9]+)x([0-9]+) ]]; then
      screen_width="${BASH_REMATCH[1]}"
      screen_height="${BASH_REMATCH[2]}"
      log "Detected screen dimensions: ${screen_width}x${screen_height}"
    else
      log "Failed to detect screen resolution, using defaults"
    fi
  fi

  # Cycling state
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
    left|right)
      pixels=$((screen_width * percentage / 100))
      aerospace resize width $pixels || handle_error "Failed to resize width"
      log "Set width to $desc ($percentage% = $pixels px)"
      ;;
    up|down)
      pixels=$((screen_height * percentage / 100))
      aerospace resize height $pixels || handle_error "Failed to resize height"
      log "Set height to $desc ($percentage% = $pixels px)"
      ;;
    *)
      handle_error "Invalid direction: $direction"
      ;;
  esac

  next_state=$(( (last_state + 1) % ${#presets[@]} ))
  echo "$direction:$next_state:$(date +%s)" > "$RESIZE_STATE_FILE"
  log "Saved state: $next_state"

  log "Resize completed"
}

show_help() {
  echo "Usage: aerospacectl [COMMAND] [ARGS]"
  echo ""
  echo "Commands:"
  echo "  update-display-cache       Update the display cache"
  echo "  smart-resize [direction]   Resize the window (left, right, up, down)"
  echo "  help                       Show this help message"
}

# Parse command
case $1 in
  update-display-cache)
    update_display_cache
    ;;
  smart-resize)
    shift
    update_display_cache & smart_resize "$@"
    ;;
  help|--help|-h|*)
    show_help
    ;;
esac

exit 0

