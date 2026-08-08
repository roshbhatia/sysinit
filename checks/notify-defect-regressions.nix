{
  pkgs,
  notifyIcons,
  ...
}:
pkgs.runCommand "notify-defect-regressions-check"
  {
    nativeBuildInputs = [
      pkgs.ripgrep
      pkgs.bash
      pkgs.jq
    ];
  }
  ''
    cfg=${../modules/home/programs/llm/runtime}
    harness=${../modules/home/programs/llm/harnesses}
    icons=${notifyIcons}
    fail=0
    note() {
      echo "FAIL: $1" >&2
      fail=1
    }

    require_file() {
      [ -f "$1" ] || note "$1 does not exist, but an assertion below greps it. Repoint the assertion; a missing file makes it pass silently."
    }
    require_file "$cfg/agent-notify.sh"
    require_file "$cfg/agent-prompt.sh"
    require_file "$cfg/agent-focus.sh"
    require_file "$harness/opencode/plugins/sysinit-notify.ts"
    require_file "$harness/pi/default.nix"
    require_file "$harness/opencode/render.nix"

    . "$cfg/agent-group.sh"

    paned="$(agent_group claude ctx 42)"
    [ "$paned" = "agent:42" ] || note "agent_group with a pane returned '$paned', expected 'agent:42'"

    a="$(agent_group claude repo-a "")"
    b="$(agent_group claude repo-b "")"
    [ "$a" != "$b" ] || note "paneless sessions share the group '$a'; the ssh fallback is gone"

    for s in agent-notify agent-prompt; do
      if ! rg -q 'agent_group "\$agent" "\$context" "\$pane"' "$cfg/$s.sh"; then
        note "$s.sh does not pass \$pane as agent_group's third argument"
      fi
    done
    rg -q 'agent_group "" "" "\$pane"' "$cfg/agent-focus.sh" ||
      note "agent-focus.sh does not rebuild the group from \$pane"

    rg -l -e 'agent:%s' -e 'agent-notify:%s' -e '"agent:\$' -e 'agent-notify:\$' \
      "$cfg/agent-group.sh" > /dev/null 2>&1 ||
      note "the group-literal patterns match nothing in agent-group.sh, so the stray scan below cannot fire. Recalibrate them against what agent_group emits."

    stray="$(
      rg -l -e 'agent:%s' -e 'agent-notify:%s' -e '"agent:\$' -e 'agent-notify:\$' \
        "$cfg" 2> /dev/null | rg -v 'agent-group\.sh' || true
    )"
    [ -z "$stray" ] || note "group literal outside agent-group.sh: $stray"

    rg -q 'dedup_key="\$\{pane\}_idle"' "$cfg/agent-notify.sh" ||
      note "idle dedup is not keyed on the pane; two panes of one harness will collapse"

    rg -q 'cksum' "$cfg/agent-notify.sh" ||
      note "the paneless dedup fallback does not hash the context; distinct sessions will collide"
    rg -q 'dedup_key=.*tr -c' "$cfg/agent-notify.sh" &&
      note "the paneless dedup fallback character-substitutes the context; that is lossy and collides"

    rg -q '@CONTENTCLICKED \| @ACTIONCLICKED\)' "$cfg/agent-prompt.sh" ||
      note "agent-prompt.sh does not route a click outcome to agent-focus"

    if cmp -s "$icons/agent.png" "$icons/claude.png"; then
      note "agent.png is byte-identical to claude.png; every unrecognized agent renders as Claude"
    fi

    . "$cfg/agent-review-suffix.sh"
    export XDG_STATE_HOME="$TMPDIR/state"
    fixtures="$XDG_STATE_HOME/agents/panes"
    mkdir -p "$fixtures"

    suffix_is() {
      local label="$1" want="$2" got="$3"
      [ "$got" = "$want" ] ||
        note "review suffix ($label): got '$got', want '$want'"
    }

    echo '{"repo":"sysinit","branch":"main","dirty":true,"since":1000}' > "$fixtures/full.json"
    suffix_is "all fields" " — sysinit · main ✱ — 1s" \
      "$(agent_review_suffix full 1001)"

    echo '{"repo":"sysinit","branch":"","dirty":false,"since":0}' > "$fixtures/nobranch.json"
    suffix_is "empty branch" " — sysinit" \
      "$(agent_review_suffix nobranch 1001)"

    echo '{"repo":"r","since":1000}' > "$fixtures/age.json"
    suffix_is "90s reads as minutes" " — r — 1m" \
      "$(agent_review_suffix age 1090)"
    suffix_is "2h reads as hours" " — r — 2h" \
      "$(agent_review_suffix age 8200)"

    suffix_is "missing file" "" \
      "$(agent_review_suffix absent 1001)"
    echo 'not json' > "$fixtures/bad.json"
    suffix_is "unparseable file" "" \
      "$(agent_review_suffix bad 1001)"

    suffix_is "clock skew" " — r" \
      "$(agent_review_suffix age 900)"

    rg -q 'agent_review_suffix' "$cfg/agent-notify.sh" ||
      note "agent-notify does not call agent_review_suffix; the body cannot name the repo, branch, or age"
    stray_suffix="$(
      rg -l 'agents/panes/\$pane\.json' "$cfg" 2> /dev/null |
        rg -v 'agent-review-suffix\.sh' || true
    )"
    [ -z "$stray_suffix" ] ||
      note "the state-file read was copied outside agent-review-suffix.sh: $stray_suffix"

    ui=${../modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua}
    rg -qU 'notifications = \{\s*\n\s*enabled = false' "$ui" ||
      note "agent-deck notifications are re-enabled in ui.lua; agent-notify is meant to be the only producer"

    rg -q 'agent-notify' "$ui" ||
      note "ui.lua does not forward agent-deck transitions into agent-notify"
    rg -q 'session\.status' "$harness/opencode/plugins/sysinit-notify.ts" ||
      note "the opencode bridge does not bind session.status; session.idle is not a plugin event"
    rg -q '"session\.idle"' "$harness/opencode/plugins/sysinit-notify.ts" &&
      note "the opencode bridge binds session.idle, which the plugin hook never receives"

    rg -q 'if not \(uv and uv.agent_state' "$ui" ||
      note "the scrape bridge does not skip hook-bridged panes; claude will double-notify"

    rg -q '^\s*"notify"$' "$harness/pi/default.nix" &&
      note "pi vendors the upstream notify extension again; agent-notify owns the toast"
    rg -qU 'attention = \{\s*\n\s*notifications = false' "$harness/opencode/render.nix" ||
      note "opencode attention.notifications is re-enabled; agent-notify owns the toast"

    [ "$fail" -eq 0 ] || exit 1
    echo "OK: six notification defects each have a failing-on-revert assertion" | tee "$out"
  ''
