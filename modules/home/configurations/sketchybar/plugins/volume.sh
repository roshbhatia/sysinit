#!/usr/bin/env bash

# Volume plugin with better error handling

get_volume() {
    osascript -e 'output volume of (get volume settings)' 2>/dev/null || echo "50"
}

get_muted() {
    osascript -e 'output muted of (get volume settings)' 2>/dev/null || echo "false"
}

VOLUME=$(get_volume)
MUTED=$(get_muted)

if [ "$MUTED" == "true" ]; then
    ICON=""
    LABEL="Muted"
    COLOR="0xffed8796"  # Red color for muted
elif [ "$VOLUME" -eq 0 ]; then
    ICON=""
    LABEL="0%"
    COLOR="0xffa5adcb"  # Default color
elif [ "$VOLUME" -lt 33 ]; then
    ICON=""
    LABEL="$VOLUME%"
    COLOR="0xffa5adcb"
elif [ "$VOLUME" -lt 66 ]; then
    ICON=""
    LABEL="$VOLUME%"
    COLOR="0xffa5adcb"
else
    ICON=""
    LABEL="$VOLUME%"
    COLOR="0xffa5adcb"
fi

sketchybar --set "$NAME" \
           icon="$ICON" \
           label="$LABEL" \
           icon.color="$COLOR"
