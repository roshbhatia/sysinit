#!/usr/bin/env bash
# shellcheck disable=all
. "$CONFIG_DIR/utils/loglib.sh"

if [ "$SENDER" = "front_app_switched" ]; then
  log_debug "Front app changed" app="$INFO"
  sketchybar --set "$NAME" label="$INFO"
fi

