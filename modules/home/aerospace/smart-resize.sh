#!/bin/bash

CACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/aerospace"
LAST_RESIZE_FILE="$CACHE_DIR/last_resize"
mkdir -p "$CACHE_DIR"

# Initialize or read last size
if [ ! -f "$LAST_RESIZE_FILE" ]; then
    echo "25" > "$LAST_RESIZE_FILE"
fi

direction=$1

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

# Use 1000 pixels as base size and calculate the target size
BASE_SIZE=1000
target_size=$(awk "BEGIN {printf \"%.0f\", $BASE_SIZE * $new_size/100}")

case $direction in
    "left")
        aerospace-command "resize smart-opposite $target_size"
        ;;
    "right")
        aerospace-command "resize smart-opposite $target_size"
        ;;
    "up")
        aerospace-command "resize smart $target_size"
        ;;
    "down")
        aerospace-command "resize smart $target_size"
        ;;
esac