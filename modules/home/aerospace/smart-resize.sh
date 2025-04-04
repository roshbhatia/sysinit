#!/bin/bash
#
# smart-resize.sh - Rectangle-style cycling window resize for Aerospace
#
# This is a stable implementation that works on all display sizes
#

# Initialize storage directory
CACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/aerospace"
LAST_RESIZE_FILE="$CACHE_DIR/last_resize"
mkdir -p "$CACHE_DIR"

# Simple logging function
log() {
  echo "[SMART-RESIZE] $1" >&2
}

# Direction from command line arguments
direction=$1
log "Starting resize in direction: $direction"

# Available sizes as percentages (25% → 33% → 50% → 67% → 75%)
SIZES=(25 33 50 67 75)
DEFAULT_SIZE="25" # Start from 25%

# Get the current size from the storage file
if [ -f "$LAST_RESIZE_FILE" ]; then
  last_size=$(cat "$LAST_RESIZE_FILE" 2>/dev/null)
  log "Previous size: $last_size%"
else
  last_size="$DEFAULT_SIZE"
  log "No previous state, starting at $DEFAULT_SIZE%"
fi

# Find the current size in our array
current_index=-1
for i in "${!SIZES[@]}"; do
  if [ "${SIZES[$i]}" = "$last_size" ]; then
    current_index=$i
    break
  fi
done

# Determine the next size
if [ "$current_index" -eq -1 ]; then
  # If current size not in our list, start from beginning
  new_size="${SIZES[0]}"
else
  # Move to next size or loop back to beginning
  next_index=$(( (current_index + 1) % ${#SIZES[@]} ))
  new_size="${SIZES[$next_index]}"
fi

# Save the new size
echo "$new_size" > "$LAST_RESIZE_FILE"
log "Setting to $new_size% width"

# Apply the resize based on direction
case $direction in
  "left"|"right")
    # For horizontal resizing, use percentage directly
    aerospace resize width-percent "$new_size"
    ;;
  "up"|"down")
    # For vertical resizing, use percentage directly
    aerospace resize height-percent "$new_size"
    ;;
  *)
    log "Unknown direction: $direction"
    exit 1
    ;;
esac

log "Resize completed successfully"
exit 0