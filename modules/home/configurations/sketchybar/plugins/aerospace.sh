#!/usr/bin/env bash
# shellcheck disable=all
. "$CONFIG_DIR/utils/loglib.sh"
. "$CONFIG_DIR/themes/catppuccin-latte.sh"

declare sid
sid=$1
if [ "$sid" = "$FOCUSED_WORKSPACE" ]; then
    log_debug "Workspace focused" workspace="$1"
    sketchybar --set space.$sid background.drawing=on label="[$sid]" label.color=$_SSDF_CM_MAUVE

else
    log_debug "Workspace unfocused" workspace="$1"
    sketchybar --set space.$sid background.drawing=off label="$sid" label.color=$_SSDF_CM_SUBTEXT_1
fi

