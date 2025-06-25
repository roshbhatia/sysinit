#!/bin/sh

PLUGIN_DIR="$CONFIG_DIR/plugins"
SPACE_ICONS=$(/opt/homebrew/bin/aerospace list-workspaces --all)
i=1
echo "$SPACE_ICONS" | while IFS= read -r workspace_name; do
    sid="$i"
    space="space=$sid icon=$workspace_name icon.padding_left=10 icon.padding_right=10 icon.y_offset=1 label.drawing=off script=$PLUGIN_DIR/space.sh click_script=/opt/homebrew/bin/aerospace summon-workspace $workspace_name"
    sketchybar --add space space."$sid" left --set space."$sid" "$space"
    i=$((i+1))
done

