#!/bin/bash

CACHE_DIR="$HOME/.cache/aerospace"
LAST_RESIZE_FILE="$CACHE_DIR/last_resize"
mkdir -p "$CACHE_DIR"

direction=$1

if [ ! -f "$LAST_RESIZE_FILE" ]; then
    echo "50" > "$LAST_RESIZE_FILE"
fi

last_size=$(cat "$LAST_RESIZE_FILE")

case $last_size in
    "50")
        new_size="67"
        ;;
    "67")
        new_size="75"
        ;;
    "75")
        new_size="25"
        ;;
    "25")
        new_size="50"
        ;;
    *)
        new_size="50"
        ;;
esac

echo "$new_size" > "$LAST_RESIZE_FILE"

size_decimal=$(echo "scale=2; $new_size/100" | bc)
opposite_decimal=$(echo "scale=2; 1-$size_decimal" | bc)

case $direction in
    "left")
        echo "resize_window_relative { width = $size_decimal, x = 0 }"
        ;;
    "right")
        echo "resize_window_relative { width = $size_decimal, x = $opposite_decimal }"
        ;;
    "top")
        echo "resize_window_relative { height = $size_decimal, y = 0 }"
        ;;
    "bottom")
        echo "resize_window_relative { height = $size_decimal, y = $opposite_decimal }"
        ;;
esac