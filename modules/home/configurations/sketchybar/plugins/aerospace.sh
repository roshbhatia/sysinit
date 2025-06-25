#!/usr/bin/env bash
# https://github.com/eleonorayaya/nix-config/blob/main/apps/sketchybar/plugins/aerospace.sh

SID=$1
if [ -z "${NAME}" ]; then
  NAME="space.${SID}"
fi

echo "Running aerospace script for $NAME"

result=$(aerospace list-workspaces --monitor 1)

if [[ $result == *"${SID}"* ]]; then
  sketchybar --set "${NAME}" display=1
else
  sketchybar --set "${NAME}" display=2
fi

if [ -n "${SID}" ] && [ "${SID}" = "${FOCUSED_WORKSPACE}" ]; then
  echo "$SID is focused"

  sketchybar --animate circ 5 --set "${NAME}" icon.highlight=on
else
  sketchybar --animate circ 5 --set "${NAME}" icon.highlight=off
fi

