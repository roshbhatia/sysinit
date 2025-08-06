#!/usr/bin/env bash

# Clock plugin with date and time

get_local_time()
                 {
    date '+%H:%M'
}

get_utc_time()
               {
    date -u '+%H:%M'
}

get_date()
           {
    date '+%a %m/%d'
}

LOCAL_TIME=$(get_local_time)
UTC_TIME=$(get_utc_time)
DATE=$(get_date)

# Different formats based on available space
if [ "$1" = "compact" ]; then
    sketchybar --set "$NAME" \
               label="$LOCAL_TIME" \
               icon=""
else
    # Show local time | UTC time with date
    sketchybar --set "$NAME" \
               label="$LOCAL_TIME │ ${UTC_TIME}Z  $DATE" \
               icon=""
fi
