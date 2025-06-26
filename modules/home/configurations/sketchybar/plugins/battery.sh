#!/usr/bin/env bash
# shellcheck disable=all
. "$CONFIG_DIR/utils/loglib.sh"

PERCENTAGE="$(pmset -g batt | grep -Eo '[0-9]+%')"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  log_error "Battery status unavailable"
  exit 0
fi

log_debug "Battery state" percentage="$PERCENTAGE" charging="$CHARGING"

case "${PERCENTAGE}" in
  9[0-9]|100) ICON=""
  ;;
  [6-8][0-9]) ICON=""
  ;;
  [3-5][0-9]) ICON=""
  ;;
  [1-2][0-9]) ICON=""
  ;;
  *) ICON=""
esac

if [ "$CHARGING" != "" ]; then
  ICON="<>"
fi

sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%"

