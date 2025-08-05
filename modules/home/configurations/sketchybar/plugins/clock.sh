#!/usr/bin/env bash

# Clock plugin with date and time

get_time()
           {
    date '+%H:%M'
}

get_date()
           {
    date '+%a %m/%d'
}

get_timezone()
               {
    date '+%Z'
}

TIME=$(get_time)
DATE=$(get_date)
TIMEZONE=$(get_timezone)

# Different formats based on available space
if [ "$1" = "compact" ]; then
    sketchybar --set "$NAME" \
               label="$TIME" \
               icon=""
else
    sketchybar --set "$NAME" \
               label="$TIME  $DATE" \
               icon=""
fi
