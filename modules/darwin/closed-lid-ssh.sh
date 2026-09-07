#!/bin/sh
set -eu

pmset_command=${1:-/usr/bin/pmset}
logger_command=${2:-/usr/bin/logger}
sleep_command=${3:-/bin/sleep}
interval=${4:-5}
marker=${5:-/var/db/sysinit/closed-lid-ssh-enabled}

cleaned_up=false

log() {
  "$logger_command" -t sysinit-closed-lid-ssh "$1"
}

reset_sleep_policy() {
  if [ "$cleaned_up" = true ]; then
    return
  fi

  "$pmset_command" -a disablesleep 0
  rm -f "$marker"
  log "system sleep enabled"
  cleaned_up=true
}

trap 'reset_sleep_policy; exit 0' HUP INT TERM
trap reset_sleep_policy EXIT

mkdir -p "$(dirname "$marker")"
touch "$marker"

"$pmset_command" -a disablesleep 1
log "system sleep disabled"

while true; do
  "$sleep_command" "$interval"
done
