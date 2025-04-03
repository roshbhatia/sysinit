#!/bin/bash
#
# smart-resize.sh - Rectangle-style cycling window resize for Aerospace
# 
# Cycle between 1/2 (balance) → 1/4 → 1/3 → 1/2 → 2/3 → 3/4 → 1/2 (balance)
#

# Initialize storage directory
CACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/aerospace"
LAST_RESIZE_FILE="$CACHE_DIR/last_resize"
mkdir -p "$CACHE_DIR"

# Debugging function
debug() {
  echo "[SMART-RESIZE] $1" >&2
}

# Direction from command line arguments
direction=$1
debug "Starting smart resize in direction: $direction"

# Get screen dimensions
get_screen_dimensions() {
  if command -v screenresolution &> /dev/null; then
    local screen_info=$(screenresolution get 2>/dev/null | grep "Display 0:" | head -1)
    if [ ! -z "$screen_info" ]; then
      local width=$(echo "$screen_info" | sed -E 's/.*Display [0-9]+: ([0-9]+)x([0-9]+)x.*/\1/')
      local height=$(echo "$screen_info" | sed -E 's/.*Display [0-9]+: ([0-9]+)x([0-9]+)x.*/\2/')
      if [ ! -z "$width" ] && [ ! -z "$height" ]; then
        echo "$width $height"
        return 0
      fi
    fi
  fi
  # Fallback to a standard MacBook Pro resolution if detection fails
  echo "2000 1200"
  return 1
}

# Get window count in workspace
get_window_count() {
  local count=$(aerospace list-windows --all --json 2>/dev/null | grep -c "window-id" || echo "2")
  echo "$count"
}

# Get screen dimensions
read screen_width screen_height <<< $(get_screen_dimensions)
debug "Screen dimensions: ${screen_width}x${screen_height}"

# Get window count
window_count=$(get_window_count)
debug "Window count: $window_count"

# Check for previous state
if [ -f "$LAST_RESIZE_FILE" ]; then
  read -r last_size last_dir < "$LAST_RESIZE_FILE" 2>/dev/null
  debug "Previous state: $last_size $last_dir"
else
  last_size="balance"
  last_dir=""
  debug "No previous state, starting at balance"
fi

# If direction changed, reset to balance first
if [ "$last_dir" != "$direction" ] && [ ! -z "$last_dir" ]; then
  debug "Direction changed from $last_dir to $direction, resetting to balance"
  aerospace balance-sizes
  last_size="balance"
fi

# Calculate next size in the cycle
case $last_size in
  "balance")
    new_size="quarter"
    # 1/4 of screen width
    target_width=$((screen_width * 25 / 100))
    debug "Setting to 1/4 width: $target_width pixels"
    ;;
  "quarter")
    new_size="third"
    # 1/3 of screen width
    target_width=$((screen_width * 33 / 100))
    debug "Setting to 1/3 width: $target_width pixels"
    ;;
  "third")
    new_size="half"
    # 1/2 of screen width
    target_width=$((screen_width * 50 / 100))
    debug "Setting to 1/2 width: $target_width pixels"
    ;;
  "half")
    new_size="two_thirds"
    # 2/3 of screen width
    target_width=$((screen_width * 67 / 100))
    debug "Setting to 2/3 width: $target_width pixels"
    ;;
  "two_thirds")
    new_size="three_quarters"
    # 3/4 of screen width
    target_width=$((screen_width * 75 / 100))
    debug "Setting to 3/4 width: $target_width pixels"
    ;;
  "three_quarters")
    new_size="balance"
    target_width=0  # balance mode
    debug "Setting to balanced (50/50)"
    ;;
  *)
    new_size="balance"
    target_width=0  # balance mode
    debug "Unknown previous state, resetting to balance"
    ;;
esac

# Save new state
echo "$new_size $direction" > "$LAST_RESIZE_FILE"

# Apply the new size
if [ "$new_size" = "balance" ]; then
  debug "Balancing windows"
  aerospace balance-sizes
else
  case $direction in
    "left"|"right")
      debug "Resizing width to $target_width pixels"
      # For horizontal resizing, use direct width setting
      aerospace resize width "$target_width"
      
      # Verify position to ensure window didn't go offscreen
      sleep 0.1
      window_info=$(aerospace list-windows --focused --json 2>/dev/null)
      if [ ! -z "$window_info" ]; then
        frame_x=$(echo "$window_info" | grep -o '"frame":{"x":[0-9\-]*' | sed -E 's/"frame":{"x":([0-9\-]*).*/\1/' || echo "0")
        
        # Safety check - if window is offscreen, rebalance
        if [ "$frame_x" -lt "-100" ] || [ "$frame_x" -gt "$screen_width" ]; then
          debug "Window position ($frame_x) appears offscreen, rebalancing"
          aerospace balance-sizes
        fi
      fi
      ;;
    "up"|"down")
      debug "For vertical resizing, using smart resize"
      aerospace resize smart "$target_width"
      ;;
  esac
fi

debug "Resize completed"
exit 0