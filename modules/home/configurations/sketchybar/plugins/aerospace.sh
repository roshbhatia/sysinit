#!/usr/bin/env bash

# Aerospace workspace plugin for sketchybar

if command -v aerospace &> /dev/null; then
    focused_workspace=$(aerospace list-workspaces --focused 2> /dev/null)
    all_workspaces=$(aerospace list-workspaces --all 2> /dev/null)

    if [ -n "$focused_workspace" ]; then
        # Show focused workspace number and create dots for all workspaces
        workspace_dots=""
        for workspace in $all_workspaces; do
            if [ "$workspace" = "$focused_workspace" ]; then
                workspace_dots="$workspace_dots●"
            else
                workspace_dots="$workspace_dots○"
            fi
        done

        sketchybar --set "$NAME" \
                   label="$focused_workspace $workspace_dots" \
                   icon=""
    else
        sketchybar --set "$NAME" label="?" icon=""
    fi
else
    # Fallback to yabai if available
    if command -v yabai &> /dev/null; then
        current_space=$(yabai -m query --spaces --space 2> /dev/null | jq -r '.index // 1' 2> /dev/null || echo "1")
        sketchybar --set "$NAME" label="$current_space" icon=""
    else
        sketchybar --set "$NAME" label="1" icon=""
    fi
fi
