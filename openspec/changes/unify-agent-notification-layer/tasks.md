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
      `CAPPED` at K=2, the scaled cap for a one-slice review, with 0 open.
      Round 1 (spec-conformance lens): 6 surviving, all fixed. The slice did not
      meet its own STOP condition; 3 of 4 defects had no regression check.
      Round 2 (implementation lens): 4 raised, 3 already closed by round 1's
      revisions, 1 new and fixed (the paneless dedup key used a lossy `tr`
      substitution, so `my session` and `my_session` shared a suppression key).
      Trend 6 to 1, declining. No round returned clean; the cap stopped it.
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
- [ ] 2.1 Set `notifications.enabled = false` in the agent-deck block of
      `ui.lua`, keeping every scraping option unchanged `deps: none`
- [ ] 2.2 Build the coverage set in `notify.nix` naming all eleven configured
      harnesses, each as bridged, deferred, or no-surface `deps: none`
- [ ] 2.3 Record cursor and copilot as no-surface with the reason `deps: 2.2`
- [ ] 2.4 Record gemini, devin, amp, crush, and goose as deferred, naming the
      hook or scraping surface each exposes and the change that will wire it;
      gemini and devin already render PreToolUse hooks, so "no surface" is
      false for them `deps: 2.2`
- [ ] 2.5 Record pi and opencode as deferred, naming slice 3 as the change that
      wires them; both keep their own producer through this slice `deps: 2.2`
- [ ] 2.6 Add a build assertion that fails when a configured harness is in
      neither the bridged, deferred, nor no-surface set (follows the
      `validateMdc` assertion at `config/cursor.nix:43`, which is consumed at
      `config/cursor.nix:58`; do not follow `pi.nix:491`, which is a `let`
      binding the module body never references and therefore never fires)
      `deps: 2.3,2.4,2.5`
- [ ] 2.7 Add a check derivation scanning the agent-deck block in `ui.lua`, the
      `extensions` list in `pi.nix`, and the OpenCode TUI attribute set for a
      re-enabled producer; fail with the producer name and name `agent-notify`
      as the owner. Without this, reverting `ui.lua` to
      `notifications.enabled = true` passes every other check `deps: 2.1`
- [ ] 2.8 Adversarial review (`adversarial-review` skill): critics attempt to
      break this slice against its spec scenarios; revise until no surviving
      objection or K=4 rounds
- [ ] 2.9 Verify: `nix flake check` and `nh darwin build` are green; inject a
      harness missing from all three sets and confirm the build fails
- [ ] 2.10 Apply: `nh darwin switch`
- [ ] 2.11 Confirm: one toast per claude wait; the statusline still names a
      scraped opencode pane; pi and OpenCode still notify through their own
      producers, which this slice deliberately leaves on

## 3. Pi and OpenCode bridges

- **SHAPE** loop
- **STOP** both harnesses raise one toast and write one state file, or the
  harness is moved to the deferred set with its own producer left on
- **MAX-ITERS** 4

- [ ] 3.1 Spike: confirm the OpenCode 1.18.4 plugin event names for session idle
      and permission request against the installed build; record the result in
      `design.md` Open Questions
- [ ] 3.2 Author `config/extensions/sysinit-notify.ts` for pi, wiring
      `session_start`, `tool_call`, `agent_settled`, and `session_shutdown` to
      `agent-state` and `agent-notify` (follows
      `config/extensions/openspec-status.ts`)
- [ ] 3.3 Confirm the bridge binds `agent_settled` and not `agent_end`, and
      that a retried or auto-compacted run raises no done toast
- [ ] 3.4 Install the pi extension through `customExtensionFiles` in `pi.nix`
- [ ] 3.5 Move pi from deferred to bridged in the coverage set, and remove
      `notify` from the vendored extension list in `pi.nix`, both in the same
      commit as 3.4, so pi is never left with no producer
- [ ] 3.6 Author the OpenCode plugin, or leave OpenCode deferred when 3.1 finds
      no usable event
- [ ] 3.7 Move OpenCode to bridged and add `attention.notifications = false` to
      the TUI config attribute set created by
      `modernize-opencode-and-pi-config` slice 1, both in the same commit as
      3.6, and only when 3.6 produced a working plugin
- [ ] 3.8 Add a build assertion that a producer may be turned off only when the
      same harness is bridged, keying on the bridge artifact itself (the
      `customExtensionFiles` entry for pi, the plugin path for OpenCode) rather
      than on the coverage-set label, so editing the label alone cannot defeat
      the guard
- [ ] 3.9 Confirm both bridges swallow every error and never fail a turn
- [ ] 3.10 Adversarial review (`adversarial-review` skill): critics attempt to
      break this slice against its spec scenarios; revise until no surviving
      objection or K=4 rounds
- [ ] 3.11 Verify: `nix flake check` and `nh darwin build` are green
- [ ] 3.12 Apply: `nh darwin switch`
- [ ] 3.13 Confirm: one pi turn and one OpenCode turn each raise one toast and
      write one state file; kill the notifier binary and confirm neither session
      breaks

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
      break this slice against its spec scenarios; revise until no surviving
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
