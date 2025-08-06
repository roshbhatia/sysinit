#!/usr/bin/env bash

# Volume plugin with popup menu support

get_volume()
             {
    osascript -e 'output volume of (get volume settings)' 2> /dev/null || echo "50"
}

get_muted()
            {
    osascript -e 'output muted of (get volume settings)' 2> /dev/null || echo "false"
}

toggle_mute()
              {
    osascript -e 'set volume with output muted'
}

set_volume()
             {
    local vol="$1"
    osascript -e "set volume output volume $vol"
}

# Handle popup actions and slider if called with arguments
if [ "$1" = "toggle" ]; then
    toggle_mute
    exit 0
elif [ "$1" = "set" ] && [ -n "$2" ]; then
    set_volume "$2"
    exit 0
elif [ "$1" = "set_slider" ]; then
    # Set volume based on slider percentage
    if [ -n "$PERCENTAGE" ]; then
        set_volume "$PERCENTAGE"
    fi
    exit 0
elif [ "$1" = "slider" ]; then
    # Update slider position based on current volume
    VOLUME=$(get_volume)
    sketchybar --set volume_slider slider.percentage="$VOLUME"
    exit 0
fi

VOLUME=$(get_volume)
MUTED=$(get_muted)

if [ "$MUTED" == "true" ]; then
    ICON="󰸈"
    LABEL="Muted"
    COLOR="0xffed8796"  # Red color for muted
elif [ "$VOLUME" -eq 0 ]; then
    ICON="󰕿"
    LABEL="0%"
    COLOR="0xffa5adcb"  # Default color
elif [ "$VOLUME" -lt 33 ]; then
    ICON="󰖀"
    LABEL="$VOLUME%"
    COLOR="0xffa5adcb"
elif [ "$VOLUME" -lt 66 ]; then
    ICON="󰖁"
    LABEL="$VOLUME%"
    COLOR="0xffa5adcb"
else
    ICON="󰕾"
    LABEL="$VOLUME%"
    COLOR="0xffa5adcb"
fi

sketchybar --set "$NAME" \
           icon="$ICON" \
           label="$LABEL" \
           icon.color="$COLOR"
