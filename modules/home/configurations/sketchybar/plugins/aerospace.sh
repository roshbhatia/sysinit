#!/usr/bin/env bash

# Aerospace workspace plugin for sketchybar

if command -v aerospace &> /dev/null; then
    focused_workspace=$(aerospace list-workspaces --focused 2>/dev/null)
    all_workspaces=$(aerospace list-workspaces --all 2>/dev/null)

    if [ -n "$focused_workspace" ]; then
        # Create workspace indicator
        workspace_indicator=""
        for workspace in $all_workspaces; do
            if [ "$workspace" = "$focused_workspace" ]; then
                workspace_indicator="$workspace_indicator●"
            else
                workspace_indicator="$workspace_indicator○"
            fi
        done

        sketchybar --set "$NAME" \
                   label="$workspace_indicator" \
                   icon=" "
    else
        sketchybar --set "$NAME" label="Aerospace" icon=" "
    fi
else
    # Fallback to yabai if available
    if command -v yabai &> /dev/null; then
        current_space=$(yabai -m query --spaces --space 2>/dev/null | jq -r '.index // 1' 2>/dev/null || echo "1")
        sketchybar --set "$NAME" label="Space $current_space" icon=" "
    else
        sketchybar --set "$NAME" label="Desktop" icon=" "
    fi
fi
