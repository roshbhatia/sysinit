#!/bin/sh

# The $NAME variable is passed from sketchybar and holds the name of
# the item invoking this script:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

if [ "$SENDER" = "mouse.clicked" ]; then
  open -a Calendar
else
  sketchybar --set "$NAME" label="$(date '+%d/%m %H:%M')"
fi

