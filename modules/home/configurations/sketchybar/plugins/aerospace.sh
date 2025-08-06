#!/usr/bin/env zsh

if [ -n "$1" ]; then
    if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
        sketchybar --set "$NAME" background.drawing=on
  else
        sketchybar --set "$NAME" background.drawing=off
  fi
    exit 0
fi
