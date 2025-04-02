#!/bin/bash

CACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/aerospace"
DISPLAY_CACHE="$CACHE_DIR/displaycache"

mkdir -p "$CACHE_DIR"

# Get display information from aerospace
display_info=$(aerospace list-monitors)

# Only update if we got valid information
if [ $? -eq 0 ] && [ ! -z "$display_info" ]; then
    echo "$display_info" > "$DISPLAY_CACHE"
fi