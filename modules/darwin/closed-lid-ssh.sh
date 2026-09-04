#!/bin/sh
set -eu

pmset_command=${1:-/usr/bin/pmset}
logger_command=${2:-/usr/bin/logger}
sleep_command=${3:-/bin/sleep}
interval=${4:-5}
marker=${5:-/var/db/sysinit/closed-lid-ssh-enabled}

last_power=""
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

while true; do
  power_source=$({ "$pmset_command" -g batt 2> /dev/null || true; } | head -n 1)

  case "$power_source" in
    *"AC Power"*)
      current_power="ac"
      disable_sleep=1
      message="system sleep disabled on AC power"
      ;;
    *)
      current_power="battery"
      disable_sleep=0
      message="system sleep enabled on battery power"
      ;;
  esac

  if [ "$current_power" != "$last_power" ]; then
    "$pmset_command" -a disablesleep "$disable_sleep"
    log "$message"
    last_power=$current_power
  fi

  "$sleep_command" "$interval"
done
