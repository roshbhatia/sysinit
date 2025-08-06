#!/usr/bin/env zsh

percentage=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
charging=$(pmset -g batt | grep 'AC Power')

[[ -z $percentage ]] && exit 0

case $percentage in
    9[0-9] | 100) icon="" ;;
    [6-8][0-9]) icon="" ;;
    [3-5][0-9]) icon="" ;;
    [1-2][0-9]) icon="" ;;
    *) icon="" ;;
esac

if [[ "$charging" != "" ]]; then
  icon=""
fi

sketchybar --set $NAME icon="$icon" label="${percentage}%"
