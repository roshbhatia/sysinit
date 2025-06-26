#!/usr/bin/env bash
# shellcheck disable=all
source "$CONFIG_DIR/utils/loglib.sh"

PLUGIN_DIR="$CONFIG_DIR/plugins"
log_info "Adding clock item to sketchybar"
sketchybar --add item clock right \
           --set clock update_freq=10 icon=  script="$PLUGIN_DIR/clock.sh"
log_info "Adding volume item to sketchybar"
sketchybar --add item volume right \
           --set volume script="$PLUGIN_DIR/volume.sh" \
           --subscribe volume volume_change
log_info "Adding battery item to sketchybar"
sketchybar --add item battery right \
           --set battery update_freq=120 script="$PLUGIN_DIR/battery.sh" \
           --subscribe battery system_woke power_source_change

