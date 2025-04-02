#!/bin/bash

CACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/aerospace"
LAST_RESIZE_FILE="$CACHE_DIR/last_resize"
DISPLAY_INFO="$CACHE_DIR/display_info"
mkdir -p "$CACHE_DIR"

# Initialize or read last size
if [ ! -f "$LAST_RESIZE_FILE" ]; then
    echo "25" > "$LAST_RESIZE_FILE"
fi

direction=$1

# Get current monitor and encode it
current_monitor=$(aerospace list-monitors | grep "$(aerospace list-workspaces --focused)" | cut -d'|' -f2 | tr -d ' ' | base64)

# Get monitor resolution from CSV using base64 encoded name
if [ -f "$DISPLAY_INFO" ]; then
    # Read CSV line by line and compare encoded names
    while IFS=, read -r name width height; do
        name=$(echo "$name" | tr -d '"')
        if [ "$name" = "$current_monitor" ]; then
            width=$(echo "$width" | tr -d '"')
            BASE_SIZE=$width
            break
        fi
    done < "$DISPLAY_INFO"
    # Fallback if no match found
    [ -z "$BASE_SIZE" ] && BASE_SIZE=1000
else
    BASE_SIZE=1000
fi

# Read current size and determine next size
last_size=$(cat "$LAST_RESIZE_FILE")
case $last_size in
    "25") new_size="33" ;;
    "33") new_size="50" ;;
    "50") new_size="67" ;;
    "67") new_size="75" ;;
    "75") new_size="25" ;;
    *) new_size="25" ;;
esac

# Save new size for next time
echo "$new_size" > "$LAST_RESIZE_FILE"

# Calculate the target size based on monitor width
target_size=$(awk "BEGIN {printf \"%.0f\", $BASE_SIZE * $new_size/100}")

case $direction in
    "left")
        aerospace resize smart-opposite "$target_size"
        ;;
    "right")
        aerospace resize smart-opposite "$target_size"
        ;;
    "up")
        aerospace resize smart "$target_size"
        ;;
    "down")
        aerospace resize smart "$target_size"
        ;;
esac