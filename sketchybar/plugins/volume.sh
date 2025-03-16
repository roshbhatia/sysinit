#!/bin/sh

# The volume_change event supplies a $INFO variable in which the current volume
# percentage is passed to the script.

if [ "$SENDER" = "volume_change" ]; then
  VOLUME="$INFO"

  case "$VOLUME" in
    [6-9][0-9]|100) ICON="󰕾"
    ;;
    [3-5][0-9]) ICON="󰖀"
    ;;
    [1-9]|[1-2][0-9]) ICON="󰕿"
    ;;
    *) ICON="󰖁"
  esac

  sketchybar --set "$NAME" icon="$ICON" label="$VOLUME%"
elif [ "$SENDER" = "mouse.clicked" ]; then
  # Toggle mute
  osascript -e 'set volume output muted to not (output muted of (get volume settings))'
  # Force update to show new state
  VOLUME=$(osascript -e 'output volume of (get volume settings)')
  
  if [ $(osascript -e 'output muted of (get volume settings)') = "true" ]; then
    ICON="󰖁"
    VOLUME="Muted"
  else
    case "$VOLUME" in
      [6-9][0-9]|100) ICON="󰕾"
      ;;
      [3-5][0-9]) ICON="󰖀"
      ;;
      [1-9]|[1-2][0-9]) ICON="󰕿"
      ;;
      *) ICON="󰖁"
    esac
    VOLUME="${VOLUME}%"
  fi
  
  sketchybar --set "$NAME" icon="$ICON" label="$VOLUME"
fi
