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

    field() { printf '%s' "$body" | jq -r "$1" 2> /dev/null; }

    pane() {
      printf '{"pane":%s,"session":"%s","repo":"%s","agent":"claude","status":"%s","reason":"","since":%s}\n' \
        "$1" "$2" "$3" "$4" "$5" > "$panes/$1.json"
    }

    run
    [ "$rc" -eq 0 ] || note "empty state exited $rc; a bar polls this and must never see non-zero"
    [ "$(field '.selection_state')" = "absent" ] ||
      note "no selected.json did not report absent, got '$(field '.selection_state')'"
    [ "$(field '.selected')" = "null" ] || note "absent selection must carry no name"

    printf '{"selected":"alpha","heartbeat":%s}\n' "$(date +%s)" > "$XDG_STATE_HOME/agents/selected.json"
    run
    [ "$(field '.selection_state')" = "fresh" ] ||
      note "a current heartbeat did not report fresh, got '$(field '.selection_state')'"
    [ "$(field '.selected')" = "alpha" ] || note "fresh selection lost its name"

    printf '{"selected":"alpha","heartbeat":%s}\n' "$(($(date +%s) - 600))" > "$XDG_STATE_HOME/agents/selected.json"
    run
    [ "$(field '.selection_state')" = "stale" ] ||
      note "an old heartbeat did not report stale, got '$(field '.selection_state')'"
    [ "$(field '.selected')" = "alpha" ] ||
      note "stale selection dropped its name; a bar can no longer dim it, only blank it"

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

    pane 4 gamma repo-b "working" 400
    run
    [ "$(field '.sessions[0].name')" = "zulu" ] ||
      note "sort order put '$(field '.sessions[0].name')' first; the worst session must lead"

    pane 5 "" repo-c "working" 500
    run
    [ "$(field '.sessions[] | select(.name=="default") | .panes')" = "1" ] ||
      note "a pane with an empty session was dropped instead of falling back to default"

    echo 'not json at all' > "$panes/6.json"
    run
    [ "$rc" -eq 0 ] || note "a malformed state file made the command exit $rc; a bar must survive one bad file"
    [ "$(field '.sessions[0].name')" = "zulu" ] ||
      note "a malformed state file broke the rollup"

    [ "$fail" -eq 0 ] || exit 1
    echo "OK: agent-sessions reports fresh/stale/absent and rolls up worst-wins" | tee "$out"
  ''
