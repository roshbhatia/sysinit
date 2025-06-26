#!/usr/bin/env bash
# shellcheck disable=all
. "$CONFIG_DIR/utils/loglib.sh"

sketchybar --set "$NAME" label="$(date '+%d/%m %H:%M')"

