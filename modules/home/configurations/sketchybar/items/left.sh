#!/usr/bin/env bash
# shellcheck disable=all
source "$CONFIG_DIR/utils/loglib.sh"
source "$CONFIG_DIR/themes/catppuccin-latte.sh"

PLUGIN_DIR="$CONFIG_DIR/plugins"

sketchybar --add event aerospace_workspace_change
for sid in $(aerospace list-workspaces --all); do

if [ "$sid" = "$FOCUSED_WORKSPACE" ]; then
    log_info "Focusing workspace" workspace="$1"
    sketchybar --set space.$sid background.drawing=on label="[$sid]" label.color=$_SSDF_CM_MAUVE
else
    sketchybar --set space.$sid background.drawing=off label="$sid" label.color=$_SSDF_CM_SUBTEXT_1
fi

    sketchybar --add item space.$sid left \
        --subscribe space.$sid aerospace_workspace_change \
        --set space.$sid \
        label="$sid" \
        click_script="aerospace workspace $sid" \
        script="$PLUGIN_DIR/aerospace.sh $sid"
done

sketchybar --add item chevron left \
           --set chevron icon= label.drawing=off

sketchybar --add item front_app left \
           --set front_app icon.drawing=off script="$PLUGIN_DIR/front_app.sh" \
           --subscribe front_app front_app_switched

