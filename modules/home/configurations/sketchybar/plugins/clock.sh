#!/usr/bin/env zsh

local_time=$(date '+%H:%M')
utc_time=$(date -u '+%H:%M')
current_date=$(date '+%a %m/%d')

sketchybar --set $NAME label="${local_time} UTC ${utc_time} | ${current_date}"
