#!/bin/bash

CACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/aerospace"
LAST_RESIZE_FILE="$CACHE_DIR/last_resize"
DISPLAY_INFO="$CACHE_DIR/display_info"
TIMEOUT=5  # Seconds before sequence expires

mkdir -p "$CACHE_DIR"

direction=$1

# Get current monitor width
current_monitor=$(aerospace list-monitors | grep "$(aerospace list-workspaces --focused)" | cut -d'|' -f2 | tr -d ' ' | base64)

if [ -f "$DISPLAY_INFO" ]; then
    while IFS=, read -r name width height; do
        name=$(echo "$name" | tr -d '"')
        if [ "$name" = "$current_monitor" ]; then
            width=$(echo "$width" | tr -d '"')
            BASE_SIZE=$width
            break
        fi
    done < "$DISPLAY_INFO"
    [ -z "$BASE_SIZE" ] && BASE_SIZE=3440  # Default to realistic width if no match
else
    BASE_SIZE=3440
fi

# Check if we should start a new sequence
current_time=$(date +%s)
if [ -f "$LAST_RESIZE_FILE" ]; then
    read -r last_size last_time last_dir < "$LAST_RESIZE_FILE" 2>/dev/null
    # Reset the sequence if timeout passed or direction changed
    if [ -z "$last_time" ] || [ $((current_time - last_time)) -gt $TIMEOUT ] || [ "$last_dir" != "$direction" ]; then
        aerospace balance-sizes
        last_size="balance"
    fi
else
    aerospace balance-sizes
    last_size="balance"
fi

# Calculate next width based on current size
case $last_size in
    "balance") new_size="25"; target_width=$((BASE_SIZE * 25 / 100)) ;;
    "25") new_size="33"; target_width=$((BASE_SIZE * 33 / 100)) ;;
    "33") new_size="50"; target_width=$((BASE_SIZE * 50 / 100)) ;;
    "50") new_size="67"; target_width=$((BASE_SIZE * 67 / 100)) ;;
    "67") new_size="75"; target_width=$((BASE_SIZE * 75 / 100)) ;;
    "75") new_size="balance"; target_width=0 ;;
    *) new_size="balance"; target_width=0 ;;
esac

# Save new size, timestamp, and direction
echo "$new_size $current_time $direction" > "$LAST_RESIZE_FILE"

if [ "$new_size" = "balance" ]; then
    aerospace balance-sizes
else
    case $direction in
        "left")
            # For left, we resize the window to the left
            aerospace resize width-from-start "$target_width"
            ;;
        "right")
            # For right, we resize the window to the right
            aerospace resize width "$target_width"
            ;;
        "up"|"down")
            # For vertical resizing, use height instead of width
            # This case matches the current keybindings for horizontal only
            aerospace resize height "$target_width"
            ;;
    esac
fi