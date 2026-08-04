## 1. The rollup command

- **SHAPE** graph

- [x] 1.1 Add `runtime/agent-sessions.sh`: read the per-pane state bus and `sy list`,
      roll up worst-wins per session, print JSON, always exit 0 (follows
      `runtime/agent-review.sh`, the existing read-only reporting command)
- [x] 1.2 Build it in `runtime/default.nix` beside `agent-review`, and install it via
      `llm/default.nix` `deps:` 1.1
- [x] 1.3 Publish the selection with a heartbeat from `ui.lua`'s existing
      `update-status` tick, so a reader can tell a live mux from a dead one
      `deps:` 1.1
- [x] 1.4 Add `checks/agent-sessions-rollup.nix`: fixture-driven, asserting the three
      selection states and the worst-wins ordering by content rather than by exit
      code `deps:` 1.3
- [x] 1.5 Mutation test the check. Two mutations: flipping `fresh` to `stale` was
      caught; replacing the rank sort with a name sort was NOT, because the fixture's
      waiting session was named `beta`, first either way. Renamed it `zulu`, which
      sorts last alphabetically and first by rank, and the mutation now fails
      `deps:` 1.4
- [x] 1.6 Run `nix flake check` and confirm it exits 0 `deps:` 1.5
- [x] 1.7 Adversarial review (`adversarial-review` skill): critics attempt to break
      the command against the proposal `Behavior` criteria and D2 and D4; revise until
      the loop reaches a terminal state (see the skill for the scaled round cap).
      Adversarial review: waived by owner for this phase, on the grounds that the
      fixture check asserts each Behavior criterion by content and both mutations were
      exercised `deps:` 1.6

## 2. The two bars

- **SHAPE** graph

- [x] 2.1 Add the sketchybar widget (follows
      `sketchybar/lua/sysinit/pkg/widgets/front_app.lua`), shown only while WezTerm is
      the front app, dimming a stale selection with `foreground_muted`
- [x] 2.2 Register it in `sketchybar/lua/sysinit/init.lua` `deps:` 2.1
- [x] 2.3 Add the waybar `custom/agent-sessions` module reading the same command, with
      a `.stale` CSS rule so Linux dims the same state the same way `deps:` 2.1
- [x] 2.4 Verify the waybar module evaluates into arrakis's config and its jq program
      produces correct output for both fresh and stale, run against real command
      output rather than read `deps:` 2.3
- [x] 2.5 Fix what that verification found: jq resolved `.selected` against the
      session object instead of the root, so the exclude-the-selected filter never
      matched; and the widget named a nonexistent colour key behind an `or` fallback,
      which would have rendered stale identically to fresh `deps:` 2.4
- [x] 2.6 Run `nix flake check` and confirm arrakis still evaluates `deps:` 2.5
- [x] 2.7 Adversarial review (`adversarial-review` skill): critics attempt to break
      the bar consumers against the proposal `Behavior` criteria and D3, asking what
      input makes the chip lie and whether any check would notice; revise until the
      loop reaches a terminal state (see the skill for the scaled round cap)
      `deps:` 2.6

## 3. Rollout

- [x] 3.1 Build only: `nh darwin build` from `sysinit.laurel`, which writes no system
      change
- [x] 3.2 Apply: `nh darwin switch` from `sysinit.laurel`, gated on `nix flake check`
      and `nh darwin build` exiting 0
- [x] 3.3 Confirm: the chip renders. `sketchybar --query agent_sessions` reports
      `drawing=on`, icon `󰆍`, label `default`, which is the selected session
- [x] 3.4 Four faults were fixed before it rendered, and only the last was the cause.
      launchd's PATH carries a literal unexpanded `$USER`; an item created
      `drawing = false` never receives `routine` so it cannot show itself; a cached
      front-app flag made the chip depend on callback ordering; and `sbar.exec`
      auto-decodes JSON stdout into a Lua table, so a callback written for a string
      raised, and sbarLua swallows a raise inside that callback
- [x] 3.5 Method note: five switches went to hypotheses before instrumenting. A
      marker line appended from inside the shell command, then from inside the
      callback, located it in one switch. Prefer instrumenting a silent failure over
      predicting it; the swallowed error made every prediction unfalsifiable
