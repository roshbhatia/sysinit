#!/usr/bin/env bash

# Front app display plugin

get_front_app() {
    osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null
}

get_app_icon() {
    local app_name="$1"
    case "$app_name" in
        "Finder") echo "󰀶" ;;
        "Safari") echo "" ;;
        "Firefox") echo "󰈹" ;;
        "Chrome"*) echo "" ;;
        "Code"*|"Visual Studio Code") echo "󰨞" ;;
        "Terminal"*) echo "" ;;
        "iTerm"*) echo "" ;;
        "WezTerm") echo "" ;;
        "Slack") echo "󰒱" ;;
        "Discord") echo "󰙯" ;;
        "Spotify") echo "" ;;
        "Music") echo "" ;;
        "Mail") echo "󰇮" ;;
        "Calendar") echo "" ;;
        "Notes") echo "" ;;
        "System Preferences"|"System Settings") echo "" ;;
        *) echo "" ;;
    esac
}

FRONT_APP=$(get_front_app)

if [ -n "$FRONT_APP" ]; then
    APP_ICON=$(get_app_icon "$FRONT_APP")

    # Truncate long app names
    if [ ${#FRONT_APP} -gt 15 ]; then
        FRONT_APP=$(echo "$FRONT_APP" | cut -c1-15)...
    fi

    sketchybar --set "$NAME" \
               label="$FRONT_APP" \
               icon="$APP_ICON"
else
    sketchybar --set "$NAME" label="Desktop" icon=""
fi
