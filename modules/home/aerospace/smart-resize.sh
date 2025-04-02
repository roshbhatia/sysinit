#!/bin/bash

CACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/aerospace"
LAST_RESIZE_FILE="$CACHE_DIR/last_resize"
DISPLAY_CACHE="$CACHE_DIR/displaycache"
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

# Convert percentage to decimal
size_decimal=$(echo "scale=3; $new_size/100" | bc)

case $direction in
    "left")
        aerospace-command "move left"
        aerospace-command "resize width relative $size_decimal"
        ;;
    "right")
        aerospace-command "move right"
        aerospace-command "resize width relative $size_decimal"
        ;;
    "up")
        aerospace-command "move up"
        aerospace-command "resize height relative $size_decimal"
        ;;
    "down")
        aerospace-command "move down"
        aerospace-command "resize height relative $size_decimal"
        ;;
esac