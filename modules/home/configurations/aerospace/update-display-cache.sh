#!/bin/bash

CACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/aerospace"
DISPLAY_CACHE="$CACHE_DIR/displaycache"
DISPLAY_INFO="$CACHE_DIR/display_info"

mkdir -p "$CACHE_DIR"

# Clear existing files for fresh data
rm -f "$DISPLAY_INFO" "$DISPLAY_CACHE"

# Get display information from aerospace and encode monitor name
if command -v aerospace >/dev/null 2>&1; then
    display_info=$(aerospace list-monitors | while read -r line; do
        id=$(echo "$line" | cut -d'|' -f1)
        name=$(echo "$line" | cut -d'|' -f2 | tr -d ' ' | base64)
        echo "$id | $name"
    done)
else
    echo "Aerospace command not found, using fallback" >&2
    display_info=""
fi

# Only update if we got valid information
if [ $? -eq 0 ] && [ ! -z "$display_info" ]; then
    echo "$display_info" > "$DISPLAY_CACHE"
fi

# Try to get real screen resolution using screenresolution tool first
if command -v screenresolution &> /dev/null; then
    echo "Using screenresolution to get display information" >&2
    # Get focused monitor from aerospace
    FOCUSED_MONITOR_INFO=$(aerospace list-monitors --focused --json 2>/dev/null)
    FOCUSED_MONITOR_ID=$(echo "$FOCUSED_MONITOR_INFO" | jq -r '.[0]["monitor-id"]' 2>/dev/null)

    if [ ! -z "$FOCUSED_MONITOR_ID" ] && [ "$FOCUSED_MONITOR_ID" != "null" ]; then
        # Adjust for index difference (aerospace is 1-indexed, screenresolution is 0-indexed)
        SCREEN_INDEX=$((FOCUSED_MONITOR_ID - 1))

        # Get resolution from screenresolution tool
        SCREEN_INFO=$(screenresolution get 2>/dev/null | grep "Display $SCREEN_INDEX:" | sed -E 's/.*Display [0-9]+: ([0-9]+)x([0-9]+)x.*/\1/')

        if [ ! -z "$SCREEN_INFO" ]; then
            # Get monitor name
            monitor_name=$(echo "$FOCUSED_MONITOR_INFO" | jq -r '.[0]["monitor-name"]' | tr -d ' ' | base64)

            echo "Found real screen width: $SCREEN_INFO" >&2
            echo "\"$monitor_name\",\"$SCREEN_INFO\"" > "$DISPLAY_INFO"
            exit 0
        fi
    fi
fi

# Fallback to system_profiler if screenresolution fails
echo "Falling back to system_profiler for display information" >&2
if command -v system_profiler >/dev/null 2>&1; then
    system_profiler SPDisplaysDataType -json | jq -r '.SPDisplaysDataType[0].spdisplays_ndrvs[] | [(.["_name"] | gsub("\\s+"; "") | @base64), (.["_spdisplays_pixels"] | split(" x ") | .[0])] | @csv' > "$DISPLAY_INFO"
else
    echo "system_profiler command not found, using device detection fallback" >&2
fi

# If still empty, use device detection
if [ ! -s "$DISPLAY_INFO" ]; then
    echo "Fallback: Using device detection for display" >&2
    # Try to get monitor name from aerospace if available
    if command -v aerospace >/dev/null 2>&1; then
        monitor_name=$(aerospace list-monitors | head -1 | cut -d'|' -f2 | tr -d ' ' | base64)
    else
        # Fallback to a generic name if aerospace isn't available
        monitor_name=$(echo "BuiltInDisplay" | base64)
    fi

    # Use sysctl to detect device if available
    if command -v sysctl &> /dev/null; then
        DEVICE_MODEL=$(sysctl -n hw.model)
        echo "Detected device model: $DEVICE_MODEL" >&2
    else
        DEVICE_MODEL=""
        echo "sysctl not available, using generic defaults" >&2
    fi

    # Check for common MacBook models and assign appropriate resolutions
    if [[ "$DEVICE_MODEL" == *"MacBookPro18"* ]]; then
        # MacBook Pro 16-inch (2021+)
        echo "\"$monitor_name\",\"3456\"" > "$DISPLAY_INFO"
        echo "Added hardcoded value for 16-inch MacBook Pro (3456)" >&2
    elif [[ "$DEVICE_MODEL" == *"MacBookPro16"* ]]; then
        # Previous generation 16-inch MacBook Pro
        echo "\"$monitor_name\",\"3072\"" > "$DISPLAY_INFO"
        echo "Added hardcoded value for 16-inch MacBook Pro (3072)" >&2
    elif [[ "$DEVICE_MODEL" == *"MacBookPro14"* || "$DEVICE_MODEL" == *"MacBookPro17"* ]]; then
        # 14-inch MacBook Pro
        echo "\"$monitor_name\",\"3024\"" > "$DISPLAY_INFO"
        echo "Added hardcoded value for 14-inch MacBook Pro (3024)" >&2
    elif command -v aerospace &> /dev/null && [[ "$(aerospace list-monitors | head -1 | cut -d'|' -f2)" == *"Built-in Retina Display"* ]]; then
        # Generic fallback for any MacBook with Retina display
        echo "\"$monitor_name\",\"3456\"" > "$DISPLAY_INFO"
        echo "Added fallback value for Built-in Retina Display (3456)" >&2
    else
        # Generic fallback for external monitors
        echo "\"$monitor_name\",\"2560\"" > "$DISPLAY_INFO"
        echo "Added generic fallback value for display (2560)" >&2
    fi
fi

