#!/usr/bin/env bash
# shellcheck disable=all
. "$CONFIG_DIR/utils/loglib.sh"

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    log_debug "Workspace focused" workspace="$1"
    sketchybar --set "[$NAME]" background.drawing=on
else
    log_debug "Workspace unfocused" workspace="$1"
    sketchybar --set "$NAME" background.drawing=off
fi

