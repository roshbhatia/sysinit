#!/bin/bash

CACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/aerospace"
DISPLAY_CACHE="$CACHE_DIR/displaycache"
DISPLAY_INFO="$CACHE_DIR/display_info"

mkdir -p "$CACHE_DIR"

# Get display information from aerospace and encode monitor name
display_info=$(aerospace list-monitors | while read -r line; do
    id=$(echo "$line" | cut -d'|' -f1)
    name=$(echo "$line" | cut -d'|' -f2 | tr -d ' ' | base64)
    echo "$id | $name"
done)

# Only update if we got valid information
if [ $? -eq 0 ] && [ ! -z "$display_info" ]; then
    echo "$display_info" > "$DISPLAY_CACHE"
fi

# Get detailed display information using system_profiler, normalize names, and output as CSV
system_profiler SPDisplaysDataType -json | jq -r '.SPDisplaysDataType[0].spdisplays_ndrvs[] | [(.["_name"] | gsub("\\s+"; "") | @base64), (.["_spdisplays_pixels"] | split(" x ") | .[0]), (.["_spdisplays_pixels"] | split(" x ") | .[1])] | @csv' > "$DISPLAY_INFO"