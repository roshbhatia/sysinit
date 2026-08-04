# `agent-sessions` is what both status bars read, so its contract is load-bearing
# in three ways that a passing exit code does not cover:
#
#   1. It must ALWAYS exit 0. A bar polls it on a timer, so a non-zero exit for the
#      ordinary idle case would make every bar render an error as its steady state.
#   2. `selection_state` must distinguish fresh from stale from absent. Without that
#      a bar shows the last-focused session forever after WezTerm quits, because
#      "gone" and "current" are otherwise the same bytes. This is the whole reason
#      the heartbeat exists.
#   3. The rollup must be worst-wins per session, so the bar and the SUPER+s tree
#      never disagree about which session needs attention.
#
# Driven against written state files rather than a live mux, because a check cannot
# have a WezTerm. `wezterm` is deliberately absent from PATH here, which exercises
# the have_live=0 branch: with no mux to ask, the script trusts the state files
# instead of dropping every session.
{
  pkgs,
  lib,
  ...
}:
let
  runtime = import ../modules/home/programs/llm/runtime { inherit pkgs lib; };
in
pkgs.runCommand "agent-sessions-rollup-check"
  {
    nativeBuildInputs = [
      pkgs.jq
      pkgs.coreutils
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    export XDG_STATE_HOME="$TMPDIR/state"
    panes="$XDG_STATE_HOME/agents/panes"
    mkdir -p "$panes" "$HOME"

    gate=${lib.getExe runtime.sessionsScript}
    fail=0
    note() {
      echo "FAIL: $1" >&2
      fail=1
    }

    run() {
      set +e
      body="$("$gate" 2>&1)"
      rc=$?
      set -e
    }

    # `body`, never `out`: $out is the derivation's output path, and shadowing it
    # makes the final `tee "$out"` write to a filename that is the whole JSON.
    field() { printf '%s' "$body" | jq -r "$1" 2> /dev/null; }

    # Statuses are quoted because `done` is a shell keyword, and an unquoted one
    # reads as the end of a loop body rather than as an argument.
    pane() {
      printf '{"pane":%s,"session":"%s","repo":"%s","agent":"claude","status":"%s","reason":"","since":%s}\n' \
        "$1" "$2" "$3" "$4" "$5" > "$panes/$1.json"
    }

    # --- absent: nothing at all, and it must still be a clean, usable answer ----
    run
    [ "$rc" -eq 0 ] || note "empty state exited $rc; a bar polls this and must never see non-zero"
    [ "$(field '.selection_state')" = "absent" ] ||
      note "no selected.json did not report absent, got '$(field '.selection_state')'"
    [ "$(field '.selected')" = "null" ] || note "absent selection must carry no name"

    # --- fresh: a current heartbeat -------------------------------------------
    printf '{"selected":"alpha","heartbeat":%s}\n' "$(date +%s)" > "$XDG_STATE_HOME/agents/selected.json"
    run
    [ "$(field '.selection_state')" = "fresh" ] ||
      note "a current heartbeat did not report fresh, got '$(field '.selection_state')'"
    [ "$(field '.selected')" = "alpha" ] || note "fresh selection lost its name"

    # --- stale: an old heartbeat keeps the name so a bar can dim it ------------
    printf '{"selected":"alpha","heartbeat":%s}\n' "$(($(date +%s) - 600))" > "$XDG_STATE_HOME/agents/selected.json"
    run
    [ "$(field '.selection_state')" = "stale" ] ||
      note "an old heartbeat did not report stale, got '$(field '.selection_state')'"
    [ "$(field '.selected')" = "alpha" ] ||
      note "stale selection dropped its name; a bar can no longer dim it, only blank it"

    # --- worst-wins rollup ----------------------------------------------------
    # One session, three panes, three statuses. `waiting` outranks `done` outranks
    # `working`, so the session's status is waiting and blocked counts all three.
    pane 1 zulu repo-a "working" 100
    pane 2 zulu repo-a "done" 200
    pane 3 zulu repo-a "waiting" 300
    run
    [ "$(field '.sessions[] | select(.name=="zulu") | .status')" = "waiting" ] ||
      note "worst-wins failed: zulu reported '$(field '.sessions[] | select(.name=="zulu") | .status')', expected waiting"
    [ "$(field '.sessions[] | select(.name=="zulu") | .panes')" = "3" ] ||
      note "zulu did not count 3 panes"
    [ "$(field '.sessions[] | select(.name=="zulu") | .blocked')" = "3" ] ||
      note "zulu did not count 3 blocked panes"

    # A second session that is merely working must sort below the waiting one, so
    # the bar names the session that actually needs the owner.
    #
    # The names matter: `zulu` is the waiting one and sorts LAST alphabetically,
    # so an assertion that it leads distinguishes rank ordering from name ordering.
    # An earlier fixture used `beta`, which is first either way, so replacing the
    # rank sort with a name sort passed the check. Mutation testing found that.
    pane 4 gamma repo-b "working" 400
    run
    [ "$(field '.sessions[0].name')" = "zulu" ] ||
      note "sort order put '$(field '.sessions[0].name')' first; the worst session must lead"

    # --- a pane with no session falls back rather than vanishing --------------
    pane 5 "" repo-c "working" 500
    run
    [ "$(field '.sessions[] | select(.name=="default") | .panes')" = "1" ] ||
      note "a pane with an empty session was dropped instead of falling back to default"

    # --- malformed input must not take the whole report down -------------------
    echo 'not json at all' > "$panes/6.json"
    run
    [ "$rc" -eq 0 ] || note "a malformed state file made the command exit $rc; a bar must survive one bad file"
    [ "$(field '.sessions[0].name')" = "zulu" ] ||
      note "a malformed state file broke the rollup"

    [ "$fail" -eq 0 ] || exit 1
    echo "OK: agent-sessions reports fresh/stale/absent and rolls up worst-wins" | tee "$out"
  ''
