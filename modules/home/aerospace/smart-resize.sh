#!/bin/bash

CACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/aerospace"
LAST_RESIZE_FILE="$CACHE_DIR/last_resize"
DISPLAY_INFO="$CACHE_DIR/display_info"
TIMEOUT=5  # Seconds before sequence expires

mkdir -p "$CACHE_DIR"

direction=$1

# First check if display info exists, if not update it
if [ ! -s "$DISPLAY_INFO" ]; then
    echo "Display info missing or empty, running update script" >&2
    bash "$(dirname "$0")/update-display-cache.sh"
fi

# Function to get current screen resolution using screenresolution tool
get_current_resolution() {
    # Get focused monitor from aerospace
    local FOCUSED_INFO=$(aerospace list-monitors --focused --json 2>/dev/null)
    local FOCUSED_ID=$(echo "$FOCUSED_INFO" | jq -r '.[0]["monitor-id"]' 2>/dev/null)
    
    if [ ! -z "$FOCUSED_ID" ] && [ "$FOCUSED_ID" != "null" ]; then
        # Adjust for index difference
        local SCREEN_INDEX=$((FOCUSED_ID - 1))
        
        if command -v screenresolution &> /dev/null; then
            local RESOLUTION=$(screenresolution get 2>/dev/null | grep "Display $SCREEN_INDEX:" | sed -E 's/.*Display [0-9]+: ([0-9]+)x([0-9]+)x.*/\1/')
            if [ ! -z "$RESOLUTION" ]; then
                echo "$RESOLUTION"
                return 0
            fi
        fi
    fi
    return 1
}

# First try to get current resolution directly
CURRENT_RES=$(get_current_resolution)
if [ ! -z "$CURRENT_RES" ]; then
    echo "Using active screen resolution: $CURRENT_RES" >&2
    BASE_SIZE=$CURRENT_RES
else
    # Fall back to cached display info
    if [ -f "$DISPLAY_INFO" ]; then
        # Debug: Show display info content
        echo "Display info content:" >&2
        cat "$DISPLAY_INFO" >&2
        
        # Get display width from cache file
        BASE_SIZE=$(head -1 "$DISPLAY_INFO" | cut -d',' -f2 | tr -d '"')
        
        # If we still couldn't get a base size or it's the generic 2560 value, try device detection
        if [ -z "$BASE_SIZE" ] || [ "$BASE_SIZE" = "2560" ]; then
            # Use sysctl to detect device
            DEVICE_MODEL=$(sysctl -n hw.model 2>/dev/null)
            
            # Determine screen width based on model
            case "$DEVICE_MODEL" in
                *"MacBookPro18"*) BASE_SIZE=3456 ;; # 16-inch MacBook Pro 2021+
                *"MacBookPro16"*) BASE_SIZE=3072 ;; # Previous generation 16-inch MacBook Pro
                *"MacBookPro14"*|*"MacBookPro17"*) BASE_SIZE=3024 ;; # 14-inch MacBook Pro
                *) BASE_SIZE=3456 ;; # Default to 16-inch M1/M2 Pro MacBook size
            esac
            
            echo "Using model-based screen width: $BASE_SIZE (Model: $DEVICE_MODEL)" >&2
        else
            echo "Using display width from cache: $BASE_SIZE" >&2
        fi
    else
        echo "Error: Display info file not found. Running update-display-cache.sh..." >&2
        bash "$(dirname "$0")/update-display-cache.sh"
        
        # Try again after running the update script
        if [ -f "$DISPLAY_INFO" ]; then
            BASE_SIZE=$(head -1 "$DISPLAY_INFO" | cut -d',' -f2 | tr -d '"')
            if [ -z "$BASE_SIZE" ] || [ "$BASE_SIZE" = "2560" ]; then
                # Use sysctl for device model detection as fallback
                DEVICE_MODEL=$(sysctl -n hw.model 2>/dev/null)
                case "$DEVICE_MODEL" in
                    *"MacBookPro18"*) BASE_SIZE=3456 ;; # 16-inch MacBook Pro 2021+
                    *"MacBookPro16"*) BASE_SIZE=3072 ;; # Previous generation 16-inch
                    *"MacBookPro14"*|*"MacBookPro17"*) BASE_SIZE=3024 ;; # 14-inch
                    *) BASE_SIZE=3456 ;; # Default fallback
                esac
                echo "Using model-based screen width after update: $BASE_SIZE (Model: $DEVICE_MODEL)" >&2
            fi
        else
            # Last resort fallback based on model detection
            DEVICE_MODEL=$(sysctl -n hw.model 2>/dev/null)
            case "$DEVICE_MODEL" in
                *"MacBookPro18"*) BASE_SIZE=3456 ;;
                *"MacBookPro16"*) BASE_SIZE=3072 ;;
                *"MacBookPro14"*|*"MacBookPro17"*) BASE_SIZE=3024 ;;
                *) BASE_SIZE=3456 ;;
            esac
            echo "Using last resort model-based width: $BASE_SIZE (Model: $DEVICE_MODEL)" >&2
        fi
    fi
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
    # Get available resize options for verification
    resize_options=$(aerospace resize --help 2>&1 | grep -o '(width|height|smart|smart-opposite)' || echo "width height smart smart-opposite")
    echo "Available resize options: $resize_options" >&2
    
    case $direction in
        "left")
            # For left, resize to a specific width
            if [[ "$resize_options" == *"width"* ]]; then
                echo "Resizing width to $target_width" >&2
                aerospace resize width "$target_width"
            else
                echo "Fallback to smart resize" >&2
                aerospace resize smart "$target_width"
            fi
            ;;
        "right")
            # For right, resize width
            echo "Resizing width to $target_width" >&2
            aerospace resize width "$target_width"
            ;;
        "up"|"down")
            # For vertical resizing, use height
            echo "Resizing height to $target_width" >&2
            aerospace resize height "$target_width"
            ;;
    esac
fi