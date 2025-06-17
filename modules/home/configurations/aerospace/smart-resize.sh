#!/bin/bash
#
# smart-resize.sh - Smarter window resizing for Aerospace
#
# This script uses Aerospace's native resize command with carefully calculated pixel values
# based on the desired ratios: 1/2, 1/3, 2/3, 1/4, 3/4
#

# Initialize storage directory
CACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/aerospace"
RESIZE_STATE_FILE="$CACHE_DIR/window_state"
mkdir -p "$CACHE_DIR"

# Simple logging function
log() {
  echo "[RECTANGLE] $1" >&2
}

# Direction from command line arguments
direction=$1
log "Starting smart resize: $direction"

# Get window state
window_info=$(aerospace list-windows --focused --format "%{window-id} | %{window-title}")
window_id=$(echo "$window_info" | awk '{print $1}')
log "Current window: $window_info"

# Try to get the current screen dimensions - use fallback if it fails
# We want a best guess for the current screen resolution
screen_width=2056  # Default value
screen_height=1329  # Default value
if command -v screenresolution &>/dev/null; then
  screen_info=$(screenresolution get 2>/dev/null)
  if [[ "$screen_info" =~ ([0-9]+)x([0-9]+) ]]; then
    screen_width="${BASH_REMATCH[1]}"
    screen_height="${BASH_REMATCH[2]}"
    log "Detected screen dimensions: ${screen_width}x${screen_height}"
  fi
fi

# State management for cycling through presets
if [ -f "$RESIZE_STATE_FILE" ]; then
  # Format is direction:state:timestamp
  last_direction=$(cat "$RESIZE_STATE_FILE" 2>/dev/null | cut -d':' -f1)
  last_state=$(cat "$RESIZE_STATE_FILE" 2>/dev/null | cut -d':' -f2)
  last_timestamp=$(cat "$RESIZE_STATE_FILE" 2>/dev/null | cut -d':' -f3)

  # Current timestamp in seconds
  current_timestamp=$(date +%s)

  # Default to 0 if parsing fails
  if [ -z "$last_state" ]; then
    last_state=0
  fi

  if [ -z "$last_timestamp" ]; then
    last_timestamp=$current_timestamp
  fi

  # Calculate time difference in seconds
  time_diff=$((current_timestamp - last_timestamp))

  if [ "$last_direction" != "$direction" ]; then
    log "Direction changed from $last_direction to $direction, resetting state"
    last_state=0
  elif [ $time_diff -gt 5 ]; then
    # If more than 5 seconds have passed, reset the state
    log "More than 5 seconds since last resize, resetting state"
    last_state=0
  else
    log "Continuing with direction $direction, state $last_state (${time_diff}s ago)"
  fi
else
  last_state=0
  log "No previous state, starting fresh with state $last_state"
fi

# Apply a preset resize based on the state
apply_resize_preset() {
  # These preset sizes are based on common window management patterns
  # Each entry has: "Description:Percentage"
  presets=("1/2:50" "1/3:33" "2/3:67" "1/4:25" "3/4:75")

  # Get the current preset
  current=${presets[$last_state]}
  desc=${current%:*}
  percentage=${current#*:}

  # Calculate next state (cycle through the presets)
  next_state=$(( (last_state + 1) % ${#presets[@]} ))

  # Apply the resize command - key difference: calculate actual pixels
  case $direction in
    "left"|"right")
      # For width, calculate pixels based on percentage of screen width
      pixels=$(( (screen_width * percentage) / 100 ))
      log "Setting width to $desc ($percentage% = $pixels px)"
      aerospace resize width $pixels
      ;;
    "up"|"down")
      # For height, calculate pixels based on percentage of screen height
      pixels=$(( (screen_height * percentage) / 100 ))
      log "Setting height to $desc ($percentage% = $pixels px)"
      aerospace resize height $pixels
      ;;
  esac

  # Save state for next time
  echo "$direction:$next_state:$(date +%s)" > "$RESIZE_STATE_FILE"
  log "Saved next state: $next_state for next time"
}

# Apply the resize
apply_resize_preset

log "Resize completed"
exit 0

