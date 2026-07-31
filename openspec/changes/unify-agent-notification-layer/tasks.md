## 1. Defect fixes in the shared scripts

- **SHAPE** loop
- **STOP** every defect has a fix and a check that fails without the fix
- **MAX-ITERS** 4

- [x] 1.1 Replace the notification group with `agent:<pane-id>` in
      `agent-notify.sh` and `agent-prompt.sh`, falling back to the existing
      `agent-notify:<agent>:<context>` form when `WEZTERM_PANE` is empty; ssh
      does not forward it and the notifier still runs (follows the existing
      group construction at `agent-notify.sh:162`)
- [x] 1.2 Rebuild the group from the pane id alone in `agent-focus.sh` and
      delete the state-file identity read used only for the group
- [x] 1.3 Key the idle dedup file on `<pane-id>_<reason>` in `agent-notify.sh`,
      falling back to `<agent>_<context>_<reason>` when the pane id is empty
- [x] 1.4 Route `@CONTENTCLICKED` and `@ACTIONCLICKED` on the approval waiter in
      `agent-prompt.sh` to `agent-focus`, keeping the Accept and Deny relay
- [x] 1.5 Add icon fetches to `notify.nix` for opencode, pi, and copilot
      (follows the pinned-hash block at `notify.nix:24`). amp, crush, goose, and
      devin are listed as intentionally generic instead: simpleicons has no
      crush or goose entry, and its "AMP" icon sources from amp.dev, which is
      Google Accelerated Mobile Pages, not Sourcegraph Amp
- [x] 1.6 Replace the `agent.png` fallback with a distinct generic glyph and
      extend the label table in `agent-notify.sh` and `agent-prompt.sh`
- [x] 1.7 Add a `nix flake check` derivation covering all four defects, each
      assertion failing when its fix is reverted (follows the hermetic
      `pkgs.runCommand` checks at `flake.nix:229`). The group assertion executes
      `agent_group` rather than grepping for the call, because a call that
      passes an empty pane reproduces the defect with the call still present
- [x] 1.8 Adversarial review (`adversarial-review` skill): terminal state
      `CLEAN`, 0 open, within the K=2 cap for a one-phase review.
      Round 1 (spec-conformance lens): 6 surviving, all fixed. The phase did not
      meet its own STOP condition; 3 of 4 defects had no regression check.
      Round 2 (implementation lens): 4 raised, 3 already closed by round 1's
      revisions, 1 new and fixed (the paneless dedup key used a lossy `tr`
      substitution, so `my session` and `my_session` shared a suppression key).
      Round 2 re-check: no surviving objection. The one objection the critic
      re-raised was a stale read: it ran `git diff HEAD`, which is empty for a
      fix that is committed rather than staged. Trend 6, 1, 0.
- [x] 1.9 Verify: `nix flake check` green (16 checks), host build green,
      `nix fmt -- --check` clean, all four defect assertions negative-tested
- [x] 1.10 Apply: `nh darwin switch`
- [ ] 1.11 Confirm: an approval toast dismisses on click; two idle panes of one
      harness both notify; a pi toast carries the pi icon and an amp toast
      carries the generic glyph. The paneless case is already confirmed on the
      live system: two sessions with no `WEZTERM_PANE` produced the distinct
      dedup keys `ctx4120745486_idle` and `ctx4143571985_idle`. The remaining
      items need a human to click a notification.

## 2. Coverage set and agent-deck

- **SHAPE** graph
- [x] 2.1 Set `notifications.enabled = false` in the agent-deck block of
      `ui.lua`, keeping every scraping option unchanged `deps: none`
- [x] 2.2 Build the coverage set in `notify.nix` naming all eleven configured
      harnesses as hook-bridged or scrape-bridged. Reasons are comments, not
      Nix string values; the data is only which set a harness is in `deps: none`
- [x] 2.3 Superseded: no harness is uncovered. cursor and copilot reach
      `agent-notify` through the agent-deck scrape bridge `deps: 2.2`
- [x] 2.4 Add agent-deck detection patterns for gemini, devin, and pi, and
      bridge every agent-deck transition into `agent-notify`, skipping panes
      that emit their own `agent_state` so a hook-bridged harness is never
      announced twice `deps: 2.2`
- [x] 2.5 Superseded by 2.4: pi and opencode are scrape-bridged now. Phase 3
      still replaces the scrape path with their richer native surfaces `deps: 2.2`
- [x] 2.6 Add a build assertion that fails when a configured harness reaches no
      notifier, and when a covered name is not configured. Forced from the
      `icons` derivation, following `config/cursor.nix:43`, consumed at
      `config/cursor.nix:58`. Both directions negative-tested `deps: 2.3,2.4,2.5`
- [x] 2.7 Extend `notify-defect-regressions` with three assertions: the
      agent-deck toast stays off, the bridge forwards into `agent-notify`, and
      the bridge skips hook-bridged panes. All three negative-tested `deps: 2.1`
- [ ] 2.8 Adversarial review (`adversarial-review` skill): critics attempt to
      break this phase against its spec scenarios; revise until no surviving
      objection or K=4 rounds
- [ ] 2.9 Verify: `nix flake check` and `nh darwin build` are green; inject a
      harness missing from all three sets and confirm the build fails
- [ ] 2.10 Apply: `nh darwin switch`
- [ ] 2.11 Confirm: one toast per claude wait; the statusline still names a
      scraped opencode pane; pi and OpenCode still notify through their own
      producers, which this phase deliberately leaves on

## 3. Pi and OpenCode bridges

- **SHAPE** loop
- **STOP** both harnesses raise one toast and write one state file, or the
  harness is moved to the deferred set with its own producer left on
- **MAX-ITERS** 4

- [x] 3.1 Spike result: OpenCode DOES expose a usable surface. The plugin `event`
      hook exists alongside `tool.execute.before/after` and `chat.*`, and the bus
      carries `session.idle` and `session.error`. A probe plugin confirmed the
      load path: OpenCode loads `.ts` from BOTH `~/.config/opencode/plugin/` and
      `~/.config/opencode/plugins/`, so the earlier audit claim that `plugins/`
      is a stale name was wrong and is corrected in the modernize change
- [x] 3.2 Author `config/extensions/sysinit-notify.ts` for pi, wiring
      `session_start`, `tool_call`, `agent_settled`, and `session_shutdown` to
      `agent-state` and `agent-notify` (follows
      `config/extensions/openspec-status.ts`)
- [x] 3.3 Confirm the bridge binds `agent_settled` and not `agent_end`, and
      that a retried or auto-compacted run raises no done toast
- [x] 3.4 Install the pi extension through `customExtensionFiles` in `pi.nix`
- [x] 3.5 Move pi from deferred to bridged in the coverage set, and remove
      `notify` from the vendored extension list in `pi.nix`, both in the same
      commit as 3.4, so pi is never left with no producer
- [x] 3.6 Author the OpenCode plugin, or leave OpenCode deferred when 3.1 finds
      no usable event
- [x] 3.7 Move OpenCode to bridged and add `attention.notifications = false` to
      the TUI config attribute set created by
      `modernize-opencode-and-pi-config` phase 1, both in the same commit as
      3.6, and only when 3.6 produced a working plugin
- [x] 3.8 Add a build assertion that a producer may be turned off only when the
      same harness is bridged, keying on the bridge artifact itself (the
      `customExtensionFiles` entry for pi, the plugin path for OpenCode) rather
      than on the coverage-set label, so editing the label alone cannot defeat
      the guard
- [x] 3.9 Confirm both bridges swallow every error and never fail a turn:
      `opencode models` exits 0 with the plugin loaded; pi exits 0 in 6.4s with
      extensions on versus 1.7s with `--no-extensions`, so the bridge adds load
      time but does not hold the process open. Every spawn is detached, unref'd,
      and wrapped, so a missing binary degrades to no notification
- [ ] 3.10 Adversarial review (`adversarial-review` skill): critics attempt to
      break this phase against its spec scenarios; revise until no surviving
      objection or K=4 rounds
- [x] 3.11 Verify: `nix flake check` and `nh darwin build` are green
- [x] 3.12 Apply: `nh darwin switch`
- [x] 3.13 Confirm: `agent-state pi done "your move"` writes a correct state
      file with the right agent, status, and repo, which is the exact call shape
      the pi bridge makes. A live toast from each harness still needs the owner:
      it requires a real interactive turn

## 4. Menu bar surface

- **SHAPE** loop
- **STOP** the widget names the worst blocked session and renders nothing when
  idle
- **MAX-ITERS** 4

- [ ] 4.1 Author `widgets/agents.lua` reading
      `$XDG_STATE_HOME/agents/panes/*.json` (follows `widgets/front_app.lua`)
- [ ] 4.2 Verify: `harden-agent-shell-terminal` has landed its state-file
      version field and its collection step; without collection the widget
      shows a permanent badge for a killed pane, because only Claude writes an
      exit event and the widget may not call the WezTerm CLI to check liveness
- [ ] 4.3 Implement worst-wins ordering matching `ui.lua`; skip a file that does
      not parse, that declares a version the widget does not understand, or that
      declares no version at all
- [ ] 4.4 Wire the click handler to `agent-focus`
- [ ] 4.5 Register the widget in the sketchybar bar configuration
- [ ] 4.6 Adversarial review (`adversarial-review` skill): critics attempt to
      break this phase against its spec scenarios; revise until no surviving
      objection or K=4 rounds
- [ ] 4.7 Verify: `nix flake check` and `nh darwin build` are green
- [ ] 4.8 Apply: `nh darwin switch`
- [ ] 4.9 Confirm: the bar restarts; the widget is empty with no agent running
      and names the session when one pane waits

## 5. Rollout

- [ ] 5.1 Verify: `openspec validate unify-agent-notification-layer` passes and
      `specutil check` reports no finding
- [ ] 5.2 Verify: `nix fmt -- --check` is clean and `git diff` is reviewed
- [ ] 5.3 Apply: stage the change and propose a commit message per the
      `writing-commit-message` skill
- [ ] 5.4 Confirm: the owner approves the staged diff before any commit
