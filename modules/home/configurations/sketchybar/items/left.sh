#!/usr/bin/env bash
set -e

# Source theme for color variables
THEME_FILE="$CONFIG_DIR/themes/catppuccin-latte.sh"
if [ -f "$THEME_FILE" ]; then
  source "$THEME_FILE"
else
  echo "[left.sh] Theme file not found: $THEME_FILE"
fi

PLUGIN_DIR="$CONFIG_DIR/plugins"

sketchybar --query bar | jq -r '.items[]' | grep '^space\.' | while read -r item; do
  sketchybar --remove item "$item"
done

sketchybar --add event aerospace_workspace_change
sketchybar --add event aerospace_workspace_monitor_change

"$PLUGIN_DIR/aerospace.sh"

sketchybar --add item chevron left \
           --set chevron icon= label.drawing=off

sketchybar --add item front_app left \
           --set front_app icon.drawing=off script="$PLUGIN_DIR/front_app.sh" \
           --subscribe front_app front_app_switched

wrapper=(
  background.drawing=off
)

separator=(
  icon=" | "
  icon.font="$ICON_FONT:Heavy:16.0"
  padding_left=15
  padding_right=15
  label.drawing=off
  associated_display=active
  icon.color="$ICON_COLOR"
)

sketchybar --add bracket wrapper '/space\..*/' \
  --set wrapper "${wrapper[@]}"

sketchybar --add item separator left \
  --set separator "${separator[@]}"

# End of file

