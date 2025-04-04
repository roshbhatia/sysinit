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

# Get screen dimensions with better detection for external displays
get_screen_dimensions() {
  # Try to use system_profiler to get display information (works with multiple displays)
  if command -v system_profiler &> /dev/null; then
    # Get information about the main display
    local display_info=$(system_profiler SPDisplaysDataType 2>/dev/null)
    
    # First try to get the resolution of the display marked as "Main"
    local main_display_res=$(echo "$display_info" | grep -A 10 "Main Display:" | grep "Resolution:" | head -1 | sed -E 's/.*Resolution: ([0-9]+) x ([0-9]+).*/\1 \2/' 2>/dev/null)
    
    # If that doesn't work, get the first resolution we find
    if [ -z "$main_display_res" ]; then
      main_display_res=$(echo "$display_info" | grep "Resolution:" | head -1 | sed -E 's/.*Resolution: ([0-9]+) x ([0-9]+).*/\1 \2/' 2>/dev/null)
    fi
    
    if [ ! -z "$main_display_res" ]; then
      echo "$main_display_res"
      return 0
    fi
  fi
  
  # Fallback to screenresolution command
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
  
  # Final fallback to a safe resolution if all detection fails
  echo "1920 1080"
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

# Detect external display (wider than normal laptop)
is_external_display=false
if [ "$screen_width" -gt 2500 ]; then
  is_external_display=true
  debug "Detected external display with width $screen_width"
fi

# Check for previous state
if [ -f "$LAST_RESIZE_FILE" ]; then
  read -r last_size last_dir last_display_size < "$LAST_RESIZE_FILE" 2>/dev/null
  debug "Previous state: $last_size $last_dir $last_display_size"
  
  # If display size changed significantly, reset state
  if [ ! -z "$last_display_size" ] && [ $last_display_size -ne $screen_width ]; then
    debug "Display size changed from $last_display_size to $screen_width, resetting state"
    last_size="balance"
    last_dir=""
  fi
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

# Adjust percentages based on display size
if [ "$is_external_display" = true ]; then
  # Ultrawide/external display percentages
  quarter_pct=20
  third_pct=30
  half_pct=50
  two_thirds_pct=67
  three_quarters_pct=80
  debug "Using external display percentages: 20/30/50/67/80"
else
  # Default laptop display percentages
  quarter_pct=25
  third_pct=33
  half_pct=50
  two_thirds_pct=67
  three_quarters_pct=75
  debug "Using laptop display percentages: 25/33/50/67/75"
fi

# Calculate next size in the cycle
case $last_size in
  "balance")
    new_size="quarter"
    target_width=$((screen_width * quarter_pct / 100))
    debug "Setting to quarter width: $target_width pixels"
    ;;
  "quarter")
    new_size="third"
    target_width=$((screen_width * third_pct / 100))
    debug "Setting to third width: $target_width pixels"
    ;;
  "third")
    new_size="half"
    target_width=$((screen_width * half_pct / 100))
    debug "Setting to half width: $target_width pixels"
    ;;
  "half")
    new_size="two_thirds"
    target_width=$((screen_width * two_thirds_pct / 100))
    debug "Setting to two thirds width: $target_width pixels"
    ;;
  "two_thirds")
    new_size="three_quarters"
    target_width=$((screen_width * three_quarters_pct / 100))
    debug "Setting to three quarters width: $target_width pixels"
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

# Save new state including current display width
echo "$new_size $direction $screen_width" > "$LAST_RESIZE_FILE"

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
      # For ultrawide displays, use percentage for vertical as well
      if [ "$is_external_display" = true ]; then
        # Calculate height percentage based on screen height
        target_height=$((screen_height * target_width / screen_width))
        debug "Resizing height to $target_height pixels (ultrawide display)"
        aerospace resize height "$target_height"
      else
        debug "For vertical resizing on standard display, using smart resize"
        aerospace resize smart "$target_width"
      fi
      ;;
  esac
fi

debug "Resize completed"
exit 0