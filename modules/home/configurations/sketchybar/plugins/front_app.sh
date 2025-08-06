#!/usr/bin/env bash

# Front app display plugin

get_front_app()
                {
    osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2> /dev/null
}

get_app_icon() {
    local app_name="$1"

    # Try sketchybar-app-font first if available
    if command -v icon_map.sh &> /dev/null; then
        local app_icon=$(icon_map.sh "$app_name" 2>/dev/null)
        if [[ -n "$app_icon" && "$app_icon" != "?" ]]; then
            echo "$app_icon"
            return
        fi
    fi

    # Enhanced icon mappings
    case "$app_name" in
        "Finder") echo "󰀶" ;;
        "Safari") echo "" ;;
        "Firefox"|"Firefox Developer Edition") echo "󰈹" ;;
        "Chrome"*) echo "" ;;
        "Code"*|"Visual Studio Code"*|"Code - Insiders") echo "󰨞" ;;
        "Terminal"*) echo "" ;;
        "iTerm"*) echo "" ;;
        "WezTerm") echo "" ;;
        "Slack") echo "󰒱" ;;
        "Discord") echo "󰙯" ;;
        "Microsoft Outlook"|"Outlook") echo "" ;;
        "Ferdium"|"Franz"|"Ferdi") echo "" ;;
        "Messenger"|"Facebook Messenger") echo "" ;;
        "Spotify") echo "" ;;
        "Music") echo "" ;;
        "Mail") echo "󰇮" ;;
        "Calendar") echo "" ;;
        "Notes") echo "" ;;
        "Notion") echo "" ;;
        "Docker Desktop"|"Docker") echo "" ;;
        "Steam") echo "" ;;
        "Activity Monitor") echo "" ;;
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
