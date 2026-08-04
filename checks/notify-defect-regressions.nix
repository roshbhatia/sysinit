# Moved verbatim from flake.nix. The expression is unchanged: its derivation path
# is asserted equal to the pre-move baseline in
# openspec/changes/decompose-flake-checks/drv-baseline.json.
{
  pkgs,
  lib,
  inputs,
  system,
  notifyIcons,
  managedFile,
  ...
}:
pkgs.runCommand "notify-defect-regressions-check"
  {
    nativeBuildInputs = [
      pkgs.ripgrep
      pkgs.bash
      # agent_review_suffix reads the state file with jq.
      pkgs.jq
    ];
  }
  ''
    cfg=${../modules/home/programs/llm/runtime}
    # The agent-agnostic scripts and the per-harness modules are two
    # roots now, so an assertion says which layer it is about.
    harness=${../modules/home/programs/llm/harnesses}
    icons=${notifyIcons}
    fail=0
    note() {
      echo "FAIL: $1" >&2
      fail=1
    }

    # Every path this check greps must exist. Without this, a moved
    # file turns an assertion into a silent pass: `set -e` exempts the
    # left side of a `&&`, and `rg` on a missing path exits 2, so an
    # `rg ... && note ...` arm neither fires nor aborts. A dead guard
    # and a live one then look identical. The `notify` guard below is
    # exactly that shape, and it sits in its silent state whenever the
    # regression it watches for is absent, which is normally.
    require_file() {
      [ -f "$1" ] || note "$1 does not exist, but an assertion below greps it. Repoint the assertion; a missing file makes it pass silently."
    }
    require_file "$cfg/agent-notify.sh"
    require_file "$cfg/agent-prompt.sh"
    require_file "$cfg/agent-focus.sh"
    require_file "$harness/opencode/plugins/sysinit-notify.ts"
    require_file "$harness/pi/default.nix"
    require_file "$harness/opencode/render.nix"

    # --- defect 1: one definition of the group string -------------
    # Execute the helper rather than grepping for its name. A call
    # that passes an empty pane produces the fallback form while
    # agent-focus removes the pane form, which is the original
    . "$cfg/agent-group.sh"

    paned="$(agent_group claude ctx 42)"
    [ "$paned" = "agent:42" ] || note "agent_group with a pane returned '$paned', expected 'agent:42'"

    # Two paneless sessions must not collapse onto one slot.
    a="$(agent_group claude repo-a "")"
    b="$(agent_group claude repo-b "")"
    [ "$a" != "$b" ] || note "paneless sessions share the group '$a'; the ssh fallback is gone"

    # Every consumer must pass the pane in position 3. Passing "" is
    # the bypass a presence-grep cannot see.
    for s in agent-notify agent-prompt; do
      if ! rg -q 'agent_group "\$agent" "\$context" "\$pane"' "$cfg/$s.sh"; then
        note "$s.sh does not pass \$pane as agent_group's third argument"
      fi
    done
    rg -q 'agent_group "" "" "\$pane"' "$cfg/agent-focus.sh" ||
      note "agent-focus.sh does not rebuild the group from \$pane"

    # No second definition may reappear outside the helper.
    #
    # The patterns must match what agent_group actually emits. They once
    # required a `$` right after the colon, matching an interpolated
    # `"agent:$pane"` form the helper no longer uses: it builds the group
    # with `printf 'agent:%s'`. So the scan matched nothing, not even the
    # canonical file, and the `rg -v agent-group.sh` filter below was the
    # tell, since it only makes sense if that file is expected to match.
    # A copied definition passed unnoticed for as long as the helper has
    # used printf. Both forms are covered now, because a second
    # definition could be written either way.
    #
    # Guarded by a positive control: if the canonical file stops matching,
    # the patterns have drifted again and the scan is dead again.
    rg -l -e 'agent:%s' -e 'agent-notify:%s' -e '"agent:\$' -e 'agent-notify:\$' \
      "$cfg/agent-group.sh" > /dev/null 2>&1 ||
      note "the group-literal patterns match nothing in agent-group.sh, so the stray scan below cannot fire. Recalibrate them against what agent_group emits."

    stray="$(
      rg -l -e 'agent:%s' -e 'agent-notify:%s' -e '"agent:\$' -e 'agent-notify:\$' \
        "$cfg" 2> /dev/null | rg -v 'agent-group\.sh' || true
    )"
    [ -z "$stray" ] || note "group literal outside agent-group.sh: $stray"

    # --- defect 2: idle dedup is scoped to the pane ---------------
    rg -q 'dedup_key="\$\{pane\}_idle"' "$cfg/agent-notify.sh" ||
      note "idle dedup is not keyed on the pane; two panes of one harness will collapse"

    # The paneless fallback must hash, not character-substitute. A
    # `tr -c` substitution collapses "my session" and "my_session"
    # onto one key, and the multi-byte "·" separator onto another.
    rg -q 'cksum' "$cfg/agent-notify.sh" ||
      note "the paneless dedup fallback does not hash the context; distinct sessions will collide"
    # Match the assignment, not the comment that explains why the
    # substitution was wrong. An unanchored grep for `tr -c` here
    # fired on this file's own rationale.
    rg -q 'dedup_key=.*tr -c' "$cfg/agent-notify.sh" &&
      note "the paneless dedup fallback character-substitutes the context; that is lossy and collides"

    # --- defect 3: an approval toast is clickable -----------------
    rg -q '@CONTENTCLICKED \| @ACTIONCLICKED\)' "$cfg/agent-prompt.sh" ||
      note "agent-prompt.sh does not route a click outcome to agent-focus"

    # --- defect 4: the fallback glyph is not a harness glyph ------
    if cmp -s "$icons/agent.png" "$icons/claude.png"; then
      note "agent.png is byte-identical to claude.png; every unrecognized agent renders as Claude"
    fi

    # --- defect 5: the toast body names where and how long --------
    # A "done" toast that says only "finished its turn" makes the
    # human switch to find out what changed. Asserted by running the
    # composer over fixtures rather than by grepping for its parts: a
    # presence-grep passes on code that is present and wrong.
    . "$cfg/agent-review-suffix.sh"
    # The helper builds the path from XDG_STATE_HOME, so a fixture
    # tree is pointed at rather than passed in.
    export XDG_STATE_HOME="$TMPDIR/state"
    fixtures="$XDG_STATE_HOME/agents/panes"
    mkdir -p "$fixtures"

    suffix_is() {
      local label="$1" want="$2" got="$3"
      [ "$got" = "$want" ] ||
        note "review suffix ($label): got '$got', want '$want'"
    }

    # Every field present. `now` is passed so the elapsed-time
    # formatting is asserted against a fixed clock.
    echo '{"repo":"sysinit","branch":"main","dirty":true,"since":1000}' > "$fixtures/full.json"
    suffix_is "all fields" " — sysinit · main ✱ — 1s" \
      "$(agent_review_suffix full 1001)"

    # An empty field must not shift the rest. This is the tab-versus-\001
    # defect: tab is IFS whitespace, so bash collapses runs of it and a
    # repo with no branch reads the timestamp as its branch name.
    echo '{"repo":"sysinit","branch":"","dirty":false,"since":0}' > "$fixtures/nobranch.json"
    suffix_is "empty branch" " — sysinit" \
      "$(agent_review_suffix nobranch 1001)"

    # Elapsed time rolls over into minutes and hours.
    echo '{"repo":"r","since":1000}' > "$fixtures/age.json"
    suffix_is "90s reads as minutes" " — r — 1m" \
      "$(agent_review_suffix age 1090)"
    suffix_is "2h reads as hours" " — r — 2h" \
      "$(agent_review_suffix age 8200)"

    # Degrade to the harness message alone rather than emitting junk.
    suffix_is "missing file" "" \
      "$(agent_review_suffix absent 1001)"
    echo 'not json' > "$fixtures/bad.json"
    suffix_is "unparseable file" "" \
      "$(agent_review_suffix bad 1001)"

    # A future timestamp must not print a negative age.
    suffix_is "clock skew" " — r" \
      "$(agent_review_suffix age 900)"

    # The notifier must call the helper, not carry its own copy.
    rg -q 'agent_review_suffix' "$cfg/agent-notify.sh" ||
      note "agent-notify does not call agent_review_suffix; the body cannot name the repo, branch, or age"
    stray_suffix="$(
      rg -l 'agents/panes/\$pane\.json' "$cfg" 2> /dev/null |
        rg -v 'agent-review-suffix\.sh' || true
    )"
    [ -z "$stray_suffix" ] ||
      note "the state-file read was copied outside agent-review-suffix.sh: $stray_suffix"

    # --- defect 6: agent-notify is the only toast producer --------
    # The agent-deck flag is a Lua literal, so nothing else reads it.
    # Reverting it to true silently restores the double-announce.
    ui=${../modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua}
    rg -qU 'notifications = \{\s*\n\s*enabled = false' "$ui" ||
      note "agent-deck notifications are re-enabled in ui.lua; agent-notify is meant to be the only producer"

    # The scrape bridge must forward into agent-notify, and must
    # skip a pane that already emits its own state. Without the skip
    # a hook-bridged harness is announced twice.
    rg -q 'agent-notify' "$ui" ||
      note "ui.lua does not forward agent-deck transitions into agent-notify"
    # Anchor on the guard itself. A bare 'uv.agent_state' also
    # matches two unrelated readers further down the file.
    # The OpenCode bridge must bind the event OpenCode actually
    # publishes. `session.idle` does not exist in the plugin event
    rg -q 'session\.status' "$harness/opencode/plugins/sysinit-notify.ts" ||
      note "the opencode bridge does not bind session.status; session.idle is not a plugin event"
    rg -q '"session\.idle"' "$harness/opencode/plugins/sysinit-notify.ts" &&
      note "the opencode bridge binds session.idle, which the plugin hook never receives"

    rg -q 'if not \(uv and uv.agent_state' "$ui" ||
      note "the scrape bridge does not skip hook-bridged panes; claude will double-notify"

    # The two producers phase 3 retired. Each is a plain literal in a
    # Nix file, so nothing else would notice it coming back.
    rg -q '^\s*"notify"$' "$harness/pi/default.nix" &&
      note "pi vendors the upstream notify extension again; agent-notify owns the toast"
    rg -qU 'attention = \{\s*\n\s*notifications = false' "$harness/opencode/render.nix" ||
      note "opencode attention.notifications is re-enabled; agent-notify owns the toast"

    [ "$fail" -eq 0 ] || exit 1
    echo "OK: six notification defects each have a failing-on-revert assertion" | tee "$out"
  ''
