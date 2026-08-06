#!/usr/bin/env bash
# Run a command in ONE reusable WezTerm pane, and optionally wait for it.
#
# Long or noisy commands (a darwin switch, a build, a test suite) belong in their
# own pane rather than in the conversation pane. Creating a pane per command
# leaves a trail of them, so this keeps a single worker pane and sends each run
# to it.
#
# Usage:
#   wtrun.sh [-w|--wait SECONDS] [-t|--tail N] [-n|--name NAME] <command...>
#   wtrun.sh --status
#   wtrun.sh --close
#
#   -w SECONDS  block until the run finishes, up to SECONDS (0 waits forever).
#               Prints the tail and exits with the command's own status, so a
#               caller can branch on it directly.
#   -t N        lines of tail to print when waiting (default 20).
#   -n NAME     name the log instead of using the run counter.
#
# Artifacts live under $XDG_STATE_HOME/agents/wtrun/<session>: <name>.log,
# <name>.rc, and last.log / last.rc pointing at the most recent run.

set -uo pipefail

die() {
  echo "wtrun: $*" >&2
  exit 1
}

[ -n "${WEZTERM_PANE:-}" ] || die "not inside a WezTerm pane"

# State is keyed by the calling pane, not shared machine-wide. One global
# worker-pane file meant two concurrent agent sessions read each other's worker
# id and sent runs into the wrong pane, and a shared `-n build` let one session's
# rc overwrite the other's. Set WTRUN_SESSION to make sessions share a worker on
# purpose.
session="${WTRUN_SESSION:-pane-${WEZTERM_PANE}}"
# The store path is read-only, so state and logs live under XDG.
here="${XDG_STATE_HOME:-$HOME/.local/state}/agents/wtrun/$session"
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
  # Never adopt the pane this script runs in: sending it a command would race the
  # caller's own shell.
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

# This took a positional log name once. A caller still written that way turns its
# name into the first word of the command, and the failure is silent when the name
# happens to be a real binary: `wtrun.sh apply "cd x && nh ..."` ran /usr/bin/apply
# and built in the wrong directory. Match that shape, a bare word followed by a
# command string, rather than testing whether the word is executable.
if [ "$#" -ge 2 ] && printf %s "$1" | grep -qE '^[a-z][a-z0-9_-]*$' &&
  printf %s "$2" | grep -q ' '; then
  die "first argument looks like a log name, not a command; use: -n $1 $(printf %q "$2")"
fi

command -v jq > /dev/null || die "jq is required to confirm the pane still exists"

# Run ids are monotonic so two runs never share a log, and `last` always points
# at the newest.
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
  # Split from the caller's own pane. Without --pane-id, split-pane targets
  # whatever pane is active, which is how a run landed in an unrelated window
  # when the owner had clicked elsewhere.
  worker="$(wezterm cli split-pane --pane-id "$WEZTERM_PANE" --bottom --percent 40 2> /dev/null)" ||
    die "could not create a pane"
  worker="${worker//[^0-9]/}"
  echo "$worker" > "$state"
  # A freshly spawned shell drops input sent before its first prompt.
  sleep 1
  # Creating a split moves focus. Give it back so the caller is not yanked out of
  # the conversation pane.
  wezterm cli activate-pane --pane-id "$WEZTERM_PANE" 2> /dev/null || true
}

# A second run under a name that is currently executing would delete the first
# run's rc, and a caller waiting on that path would then read the wrong status.
if [ -n "$queued" ] && [ "$queued" = "$name" ]; then
  die "a run named $name is already executing; use a different -n, or wait for $rc"
fi

# The command goes to a script file rather than into the sent text. Sending it
# inline would re-parse it in the worker's shell, so a quote, a newline, or a
# glob in the command would change meaning between here and there.
body="$here/$name.cmd"
{
  printf '#!/usr/bin/env zsh\n'
  # Claimed by the run that is executing, not by the sender: a queued run's
  # predecessor would otherwise clear the marker and --status would read idle
  # while work was still pending.
  printf 'print -r -- %q > %q\n' "$name" "$running"
  printf '%s\n' "$*"
} > "$body"

# The header is written here rather than emitted by the body. Emitting it would
# mean quoting the command for the worker's shell a second time, and a value
# starting with `=` or `~` changes meaning under zsh's own expansions. The log is
# opened for append below so this survives.
{
  printf '=== %s  %s\n' "$name" "$(date '+%Y-%m-%d %H:%M:%S')"
  printf '%s\n---\n' "$*"
} > "$log"

# `tee -a` appends, so the header written above survives. It shows the run live
# in the pane and captures the same bytes to the log.
# The rc write sits beside the command rather than after the pipeline, so `$?` is
# the command's own status and not tee's. The running marker is removed last, so
# a caller polling rc never reads a partial result.
# \025 is Ctrl-U: kill whatever is already sitting in the pane's line buffer
# before typing. Without it a single stray keystroke prefixes the command, which
# then silently does not run: an observed `3clear; { zsh ... }` produced no output
# and no exit code, and read as a job still in flight.
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

# Waiting is the common case: one call instead of run, sleep, then read.
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
