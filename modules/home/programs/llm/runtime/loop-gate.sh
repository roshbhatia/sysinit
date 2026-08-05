#!/usr/bin/env bash
# Turns a `STOP` condition from prose into a predicate.
#
# The spec-driven schema requires a loop phase to declare a STOP that is a
# command, but nothing ran it: the loop ended when the model decided it was
# done. This is the Stop hook that actually evaluates it.
#
# Claude Code ships two adjacent primitives and neither fits. `/loop` restarts
# on a time interval and stops when the model decides. `/goal` judges a
# condition with a small model, but its docs are explicit that it "doesn't run
# commands or read files independently" — so `/goal all tests pass` terminates
# on a transcript that CLAIMS they passed. This runs the command.
#
# Two bounds, because they fail differently (see the `adversarial-review`
# skill's terminal states):
#   CLEAN     the command exited 0. The loop succeeded.
#   CAPPED    max iterations reached. Reported as open work, never as a pass.
#   STALLED   N consecutive iterations produced byte-identical output. The loop
#             is not converging and burning the rest of the cap proves nothing.
#
# Disarmed by default. With no state file this is a no-op, so an ordinary
# session is unaffected.
#
# Usage:
#   loop-gate arm --until '<command>' [--max <n>] [--stall <n>]
#   loop-gate status
#   loop-gate clear
#   loop-gate check          # the Stop hook entrypoint; reads hook JSON on stdin

set -euo pipefail

state_dir() { echo "${SYSINIT_LOOP_GATE_DIR:-${PWD}/.sysinit}"; }
state_file() { echo "$(state_dir)/loop-gate.json"; }

die() {
  echo "loop-gate: $*" >&2
  exit 1
}

cmd_arm() {
  local until_cmd="" max=4 stall=2
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --until)
        until_cmd="${2:-}"
        shift 2
        ;;
      --max)
        max="${2:-}"
        shift 2
        ;;
      --stall)
        stall="${2:-}"
        shift 2
        ;;
      *) die "unknown flag: $1" ;;
    esac
  done
  [ -n "$until_cmd" ] || die "arm requires --until '<command>'"
  case "$max$stall" in
    *[!0-9]*) die "--max and --stall must be integers" ;;
  esac
  mkdir -p "$(state_dir)"
  jq -n --arg c "$until_cmd" --argjson m "$max" --argjson s "$stall" \
    '{until:$c, max:$m, stall:$s, iter:0, sameCount:0, lastHash:""}' \
    > "$(state_file)"
  echo "loop-gate: armed. STOP is \`$until_cmd\`; CAPPED at $max, STALLED after $stall unchanged." >&2
}

cmd_status() {
  local f
  f="$(state_file)"
  if [ ! -f "$f" ]; then
    echo "loop-gate: disarmed (no state at $f)"
    return 0
  fi
  jq -r '"loop-gate: armed\n  STOP:    \(.until)\n  iter:    \(.iter)/\(.max)\n  unchanged: \(.sameCount)/\(.stall)"' "$f"
}

cmd_clear() {
  rm -f "$(state_file)"
  echo "loop-gate: disarmed." >&2
}

# Block the stop and hand the reason back to the model as guidance.
block() {
  jq -n --arg r "$1" '{decision:"block", reason:$r}'
  exit 0
}

cmd_check() {
  local f
  f="$(state_file)"
  # Disarmed: the overwhelmingly common case. Say nothing, change nothing.
  [ -f "$f" ] || exit 0

  local input stop_active
  input="$(cat 2> /dev/null || true)"
  # Claude Code sets stop_hook_active when the stop was already blocked once by
  # a hook. Honour it: without this the gate and the harness can trade turns
  # with no way out. Claude Code also force-ends after 8 consecutive blocks,
  # which is a backstop, not a substitute for reading this flag.
  stop_active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2> /dev/null || echo false)"

  local until_cmd max stall iter same last
  until_cmd="$(jq -r '.until' "$f")"
  max="$(jq -r '.max' "$f")"
  stall="$(jq -r '.stall' "$f")"
  iter="$(jq -r '.iter' "$f")"
  same="$(jq -r '.sameCount' "$f")"
  last="$(jq -r '.lastHash' "$f")"

  local out rc hash
  set +e
  out="$(eval "$until_cmd" 2>&1)"
  rc=$?
  set -e

  if [ "$rc" -eq 0 ]; then
    rm -f "$f"
    echo "loop-gate: CLEAN after $iter iteration(s) — \`$until_cmd\` exited 0." >&2
    exit 0
  fi

  iter=$((iter + 1))
  hash="$(printf '%s' "$out" | shasum -a 256 | awk '{print $1}')"
  if [ "$hash" = "$last" ]; then
    same=$((same + 1))
  else
    same=0
  fi

  # Terminal without success. Clear the state so the next turn is not trapped,
  # and say plainly that this is open work.
  if [ "$same" -ge "$stall" ]; then
    rm -f "$f"
    echo "loop-gate: STALLED — $same iterations produced identical output from \`$until_cmd\`. Open work, not a pass." >&2
    exit 0
  fi
  if [ "$iter" -ge "$max" ]; then
    rm -f "$f"
    echo "loop-gate: CAPPED at $max iterations; \`$until_cmd\` still failing. Open work, not a pass." >&2
    exit 0
  fi

  jq -n --arg c "$until_cmd" --argjson m "$max" --argjson s "$stall" \
    --argjson i "$iter" --argjson sc "$same" --arg h "$hash" \
    '{until:$c, max:$m, stall:$s, iter:$i, sameCount:$sc, lastHash:$h}' > "$f"

  if [ "$stop_active" = "true" ]; then
    exit 0
  fi

  block "The declared STOP condition is not met (iteration ${iter}/${max}).

Command: ${until_cmd}
Exit code: ${rc}

Output:
${out}

Fix the cause and continue. Do not report this phase as done while the command fails."
}

case "${1:-}" in
  arm)
    shift
    cmd_arm "$@"
    ;;
  status) cmd_status ;;
  clear) cmd_clear ;;
  check) cmd_check ;;
  *)
    echo "usage: loop-gate arm --until '<command>' [--max n] [--stall n] | status | clear | check" >&2
    exit 2
    ;;
esac
