#!/usr/bin/env bash

# Front app display plugin

get_front_app()
                {
    osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2> /dev/null
}

get_app_icon()
               {
    local app_name="$1"

    # Try sketchybar-app-font first if available
    if command -v icon_map.sh &> /dev/null; then
        local app_icon=$(icon_map.sh "$app_name" 2> /dev/null)
        if [[ -n "$app_icon" && "$app_icon" != "?" ]]; then
            echo "$app_icon"
            return
    fi
  fi

    # Enhanced icon mappings
    case "$app_name" in
        "Finder") echo "󰀶" ;;
        "Safari") echo "" ;;
        "Firefox" | "Firefox Developer Edition") echo "󰈹" ;;
        "Chrome"*) echo "" ;;
        "Code"* | "Visual Studio Code"* | "Code - Insiders") echo "󰨞" ;;
        "Terminal"*) echo "" ;;
        "iTerm"*) echo "" ;;
        "WezTerm" | "wezterm-gui") echo "" ;;
        "Slack") echo "󰒱" ;;
        "Discord") echo "󰙯" ;;
        "Microsoft Outlook" | "Outlook") echo "" ;;
        "Ferdium" | "Franz" | "Ferdi") echo "" ;;
        "Messenger" | "Facebook Messenger") echo "" ;;
        "Spotify") echo "" ;;
        "Music") echo "" ;;
        "Mail") echo "󰇮" ;;
        "Calendar") echo "" ;;
        "Notes") echo "" ;;
        "Notion") echo "" ;;
        "Docker Desktop" | "Docker") echo "" ;;
        "Steam") echo "" ;;
        "Activity Monitor") echo "" ;;
        "System Preferences" | "System Settings") echo "" ;;
        *) echo "" ;;  # NixOS fallback icon for unknown apps
  esac
}

get_clean_app_name() {
    local app_name="$1"
    case "$app_name" in
        "wezterm-gui") echo "Wezterm" ;;
        "Code - Insiders" | "Visual Studio Code - Insiders") echo "VS Code" ;;
        "Microsoft Outlook") echo "Outlook" ;;
        "System Preferences") echo "Settings" ;;
        "System Settings") echo "Settings" ;;
        "Firefox Developer Edition") echo "Firefox Dev" ;;
        "Activity Monitor") echo "Activity" ;;
        *) echo "$app_name" ;;
    esac
}

FRONT_APP=$(get_front_app)

if [ -n "$FRONT_APP" ]; then
    APP_ICON=$(get_app_icon "$FRONT_APP")
    CLEAN_APP_NAME=$(get_clean_app_name "$FRONT_APP")

    # Truncate long app names
    if [ ${#CLEAN_APP_NAME} -gt 15 ]; then
        CLEAN_APP_NAME=$(echo "$CLEAN_APP_NAME" | cut -c1-15)...
    fi

    sketchybar --set "$NAME" \
               label="$CLEAN_APP_NAME" \
               icon="$APP_ICON"
else
    sketchybar --set "$NAME" label="Desktop" icon=""
fi
