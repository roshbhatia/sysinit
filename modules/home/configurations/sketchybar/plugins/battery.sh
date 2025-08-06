#!/usr/bin/env bash

# Battery plugin with charging status and better icons

get_battery_info()
                   {
    pmset -g batt 2> /dev/null | head -2
}

get_battery_percent()
                      {
    local battery_info="$1"
    echo "$battery_info" | grep -Eo "\d+%" | cut -d% -f1 | head -1
}

get_charging_state()
                     {
    local battery_info="$1"
    if echo "$battery_info" | grep -q "AC Power"; then
        echo "charging"
  elif   echo "$battery_info" | grep -q "Battery Power"; then
        echo "discharging"
  else
        echo "unknown"
  fi
}

get_time_remaining()
                     {
    local battery_info="$1"
    echo "$battery_info" | grep -o "\d*:\d*" | head -1
}

BATTERY_INFO=$(get_battery_info)
BATTERY_PERCENT=$(get_battery_percent "$BATTERY_INFO")
CHARGING_STATE=$(get_charging_state "$BATTERY_INFO")
TIME_REMAINING=$(get_time_remaining "$BATTERY_INFO")

# Set defaults if detection fails
BATTERY_PERCENT=${BATTERY_PERCENT:-"50"}

# Choose icon and color based on state and level
if [ "$CHARGING_STATE" == "charging" ]; then
    ICON=""
    COLOR="0xffa6da95"  # Green for charging
    if [ -n "$TIME_REMAINING" ]; then
        LABEL="$BATTERY_PERCENT% ($TIME_REMAINING)"
  else
        LABEL="$BATTERY_PERCENT% Charging"
  fi
else
    # Choose battery icon based on level
    if [ "$BATTERY_PERCENT" -gt 75 ]; then
        ICON=""
        COLOR="0xffa6da95"  # Green
  elif   [ "$BATTERY_PERCENT" -gt 50 ]; then
        ICON=""
        COLOR="0xffeed49f"  # Yellow
  elif   [ "$BATTERY_PERCENT" -gt 25 ]; then
        ICON=""
        COLOR="0xfff5a97f"  # Orange
  elif   [ "$BATTERY_PERCENT" -gt 10 ]; then
        ICON=""
        COLOR="0xffed8796"  # Red
  else
        ICON=""
        COLOR="0xffed8796"  # Red critical
  fi

    if [ -n "$TIME_REMAINING" ]; then
        LABEL="$BATTERY_PERCENT% ($TIME_REMAINING)"
  else
        LABEL="$BATTERY_PERCENT%"
  fi
fi

sketchybar --set "$NAME" \
           icon="$ICON" \
           label="$LABEL" \
           icon.color="$COLOR"

