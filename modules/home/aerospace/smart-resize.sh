#!/bin/bash

CACHE_DIR="$HOME/.cache/aerospace"
LAST_RESIZE_FILE="$CACHE_DIR/last_resize"
SCREEN_DIMS_CACHE="$CACHE_DIR/screen_dims"
CACHE_TTL=86400  # 24 hours in seconds
mkdir -p "$CACHE_DIR"

get_cached_dimensions() {
    if [ -f "$SCREEN_DIMS_CACHE" ]; then
        cache_time=$(stat -f "%m" "$SCREEN_DIMS_CACHE")
        current_time=$(date +%s)
        if [ $((current_time - cache_time)) -lt $CACHE_TTL ]; then
            cat "$SCREEN_DIMS_CACHE"
            return 0
        fi
    fi
    
    # Cache miss or expired, get new dimensions
    system_profiler SPDisplaysDataType > "$SCREEN_DIMS_CACHE"
    cat "$SCREEN_DIMS_CACHE"
}

get_display_dimensions() {
    local window_id=$1
    local window_info=$(aerospace-command "query window-info $window_id")
    local window_x=$(echo "$window_info" | grep "x:" | awk '{print $2}')
    local window_y=$(echo "$window_info" | grep "y:" | awk '{print $2}')
    
    # Parse all displays from cache
    local displays_info=$(get_cached_dimensions)
    
    # Find the display that contains the window
    while IFS= read -r line; do
        if [[ $line =~ Resolution:\ ([0-9]+)\ x\ ([0-9]+) ]]; then
            current_width="${BASH_REMATCH[1]}"
            current_height="${BASH_REMATCH[2]}"
            
            # Read next line for origin if it exists
            read -r origin_line
            if [[ $origin_line =~ Origin:\ \(([0-9-]+),([0-9-]+)\) ]]; then
                origin_x="${BASH_REMATCH[1]}"
                origin_y="${BASH_REMATCH[2]}"
                
                # Check if window is in this display
                if [ $((window_x >= origin_x)) -eq 1 ] && 
                   [ $((window_x < origin_x + current_width)) -eq 1 ] && 
                   [ $((window_y >= origin_y)) -eq 1 ] && 
                   [ $((window_y < origin_y + current_height)) -eq 1 ]; then
                    echo "$current_width $current_height"
                    return 0
                fi
            fi
        fi
    done < <(echo "$displays_info")
    
    # Fallback to main display if window not found
    echo "$displays_info" | grep Resolution | head -n1 | awk '{print $2, $4}'
}

direction=$1
current_window_id=$(aerospace-command 'query focused-window-id')

# Get dimensions for the display containing the current window
read screen_width screen_height < <(get_display_dimensions "$current_window_id")

if [ ! -f "$LAST_RESIZE_FILE" ]; then
    echo "25" > "$LAST_RESIZE_FILE"
fi

last_size=$(cat "$LAST_RESIZE_FILE")

case $last_size in
    "25")
        new_size="33"
        ;;
    "33")
        new_size="50"
        ;;
    "50")
        new_size="67"
        ;;
    "67")
        new_size="75"
        ;;
    "75")
        new_size="25"
        ;;
    *)
        new_size="25"
        ;;
esac

echo "$new_size" > "$LAST_RESIZE_FILE"

size_decimal=$(echo "scale=3; $new_size/100" | bc)
pixels_h=$(echo "scale=0; $screen_width * $size_decimal" | bc)
pixels_v=$(echo "scale=0; $screen_height * $size_decimal" | bc)

case $direction in
    "left")
        aerospace-command "resize width exact $pixels_h"
        ;;
    "right")
        aerospace-command "resize width exact $pixels_h"
        ;;
    "up")
        aerospace-command "resize height exact $pixels_v"
        ;;
    "down")
        aerospace-command "resize height exact $pixels_v"
        ;;
esac