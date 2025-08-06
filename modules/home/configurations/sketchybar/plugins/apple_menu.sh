#!/usr/bin/env zsh

choice=$(osascript << EOF
set menuItems to {"About This Mac", "System Preferences", "Activity Monitor", "Sleep", "Restart", "Shutdown", "Cancel"}
set choice to choose from list menuItems with title "System Menu" with prompt "Choose an action:" default items {"Cancel"}
if choice is false then
    return "Cancel"
else
    return choice as string
end if
EOF
)

case $choice in
    "About This Mac")
        open "/System/Applications/Utilities/System Information.app"
        ;;
    "System Preferences")
        open "/System/Applications/System Settings.app"
        ;;
    "Activity Monitor")
        open "/System/Applications/Utilities/Activity Monitor.app"
        ;;
    "Sleep")
        pmset sleepnow
        ;;
    "Restart")
        osascript -e 'tell app "System Events" to restart'
        ;;
    "Shutdown")
        osascript -e 'tell app "System Events" to shut down'
        ;;
esac
