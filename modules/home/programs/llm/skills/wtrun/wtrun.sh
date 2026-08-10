#!/usr/bin/env bash

set -uo pipefail

die() {
  echo "wtrun: $*" >&2
  exit 1
}

[ -n "${WEZTERM_PANE:-}" ] || die "not inside a WezTerm pane"

# Read one path out of the paths manifest. The layout has one owner,
# sysinit:documented-default
sysinit_state_root="${XDG_STATE_HOME:-$HOME/.local/state}"
sysinit_manifest="${SYSINIT_PATHS_MANIFEST:-$sysinit_state_root/sysinit/paths.json}"

sysinit_path() {
  [ -s "$sysinit_manifest" ] || return 1
  command -v jq > /dev/null 2>&1 || return 1
  sp_value=$(jq -er --arg k "$1" '.paths[$k] // empty' "$sysinit_manifest" 2> /dev/null) || return 1
  [ -n "$sp_value" ] || return 1
  printf '%s\n' "$sp_value"
}

session="${WTRUN_SESSION:-pane-${WEZTERM_PANE}}"
wtrun_root=$(sysinit_path agentWtrun) || wtrun_root="$sysinit_state_root/agents/wtrun"
here="$wtrun_root/$session"
mkdir -p "$here"
state="$here/worker-pane"
counter="$here/worker-runs"
running="$here/worker-running"

pane_alive() {
  [ -n "${1:-}" ] || return 1
  wezterm cli list --format json 2> /dev/null |
    jq -e --argjson id "$1" 'any(.[]; .pane_id == $id)' > /dev/null 2>&1
}

worker_id() {
  [ -f "$state" ] || return 1
  local id
  id="$(cat "$state" 2> /dev/null)"
  [ "$id" != "${WEZTERM_PANE:-}" ] || return 1
  pane_alive "$id" || return 1
  echo "$id"
}

wait_sec=""
tail_n=20
name=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -w | --wait)
      wait_sec="${2:-0}"
      shift 2
      ;;
    -t | --tail)
      tail_n="${2:-20}"
      shift 2
      ;;
    -n | --name)
      name="${2:-}"
      shift 2
      ;;
    --status)
      if id="$(worker_id)"; then
        if [ -f "$running" ]; then
          echo "worker pane $id, running $(cat "$running")"
        else
          echo "worker pane $id, idle"
        fi
      else
        echo "no worker pane"
      fi
      exit 0
      ;;
    --close)
      if id="$(worker_id)"; then
        wezterm cli kill-pane --pane-id "$id" 2> /dev/null && echo "closed pane $id"
      else
        echo "no worker pane"
      fi
      rm -f "$state" "$running"
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*) die "unknown flag: $1" ;;
    *) break ;;
  esac
done
[ "$#" -ge 1 ] || die "usage: wtrun.sh [-w SECONDS] [-t N] [-n NAME] <command...>"

if [ "$#" -ge 2 ] && printf %s "$1" | grep -qE '^[a-z][a-z0-9_-]*$' &&
  printf %s "$2" | grep -q ' '; then
  die "first argument looks like a log name, not a command; use: -n $1 $(printf %q "$2")"
fi

command -v jq > /dev/null || die "jq is required to confirm the pane still exists"

if [ -z "$name" ]; then
  n=$(($(cat "$counter" 2> /dev/null || echo 0) + 1))
  echo "$n" > "$counter"
  name="run$n"
fi
log="$here/$name.log"
rc="$here/$name.rc"
rm -f "$rc"

queued=""
[ -f "$running" ] && queued="$(cat "$running")"

worker="$(worker_id)" || {
  worker="$(wezterm cli split-pane --pane-id "$WEZTERM_PANE" --bottom --percent 40 2> /dev/null)" ||
    die "could not create a pane"
  worker="${worker//[^0-9]/}"
  echo "$worker" > "$state"
  sleep 1
  wezterm cli activate-pane --pane-id "$WEZTERM_PANE" 2> /dev/null || true
}

if [ -n "$queued" ] && [ "$queued" = "$name" ]; then
  die "a run named $name is already executing; use a different -n, or wait for $rc"
fi

body="$here/$name.cmd"
{
  printf '#!/usr/bin/env zsh\n'
  printf 'print -r -- %q > %q\n' "$name" "$running"
  printf '%s\n' "$*"
} > "$body"

{
  printf '=== %s  %s\n' "$name" "$(date '+%Y-%m-%d %H:%M:%S')"
  printf '%s\n---\n' "$*"
} > "$log"

printf '\025clear; { zsh %q; echo $? > %q; } 2>&1 | tee -a %q; rm -f %q\n' \
  "$body" "$rc" "$log" "$running" |
  wezterm cli send-text --pane-id "$worker" --no-paste

if [ -n "$queued" ]; then
  echo "pane $worker  $name queued behind $queued  log $log"
else
  echo "pane $worker  $name  log $log"
fi
ln -sf "$log" "$here/last.log"
ln -sf "$rc" "$here/last.rc"

[ -n "$wait_sec" ] || exit 0

waited=0
while [ ! -f "$rc" ]; do
  sleep 2
  waited=$((waited + 2))
  if [ "$wait_sec" != "0" ] && [ "$waited" -ge "$wait_sec" ]; then
    echo "wtrun: still running after ${wait_sec}s; poll $rc" >&2
    exit 75
  fi
done

status="$(cat "$rc")"
echo "── $name tail (exit $status)"
tail -n "$tail_n" "$log" 2> /dev/null
exit "$status"
