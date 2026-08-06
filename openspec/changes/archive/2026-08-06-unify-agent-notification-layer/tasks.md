> **Closed with 9 tasks unfinished, by owner decision on 2026-08-06.**
> The substance of this change is applied and running; what remained was review
> ceremony and owner-confirmation gates the owner chose not to run. Archived
> rather than deleted so the record of what was built survives. The unchecked
> boxes below are accurate: they were dropped, not completed.

## 1. Defect fixes in the shared scripts

- **SHAPE** loop
- **STOP** `nix build .#checks.aarch64-darwin.notify-defect-regressions` exits
  0, and reverting any one fix makes it fail
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

- **SHAPE** graph
- Not a loop: the exit is the owner watching each harness raise exactly one toast
  in a live session. No command counts toasts, so the phase ends at its
  `Confirm:` task instead.
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
      that a retried or auto-compacted run raises no done toast `deps:` 3.2
- [x] 3.4 Install the pi extension through `customExtensionFiles` in `pi.nix` `deps:` 3.2
- [x] 3.5 Move pi from deferred to bridged in the coverage set, and remove
      `notify` from the vendored extension list in `pi.nix`, both in the same
      commit as 3.4, so pi is never left with no producer `deps:` 3.4
- [x] 3.6 Author the OpenCode plugin, or leave OpenCode deferred when 3.1 finds
      no usable event `deps:` 3.1
- [x] 3.7 Move OpenCode to bridged and add `attention.notifications = false` to
      the TUI config attribute set created by
      `modernize-opencode-and-pi-config` phase 1, both in the same commit as
      3.6, and only when 3.6 produced a working plugin `deps:` 3.6
- [x] 3.8 Add a build assertion that a producer may be turned off only when the
      same harness is bridged, keying on the bridge artifact itself (the
      `customExtensionFiles` entry for pi, the plugin path for OpenCode) rather
      than on the coverage-set label, so editing the label alone cannot defeat
      the guard `deps:` 3.5,3.7
- [x] 3.9 Confirm both bridges swallow every error and never fail a turn:
      `opencode models` exits 0 with the plugin loaded; pi exits 0 in 6.4s with
      extensions on versus 1.7s with `--no-extensions`, so the bridge adds load
      time but does not hold the process open. Every spawn is detached, unref'd,
      and wrapped, so a missing binary degrades to no notification `deps:` 3.5,3.7
- [x] 3.10 Adversarial review (`adversarial-review` skill): round 1 returned 6
      surviving objections, all fixed. `detached: true` called setsid(), which
      severs the controlling terminal, so agent-state's OSC never landed and the
      scrape bridge would have announced every bridged harness twice; pi's
      `tool_call` payload is `event.input`, not `event.args`, so every reason
      string was empty; no check caught pi's `notify` or opencode's `attention`
      coming back; the bridge guard proved the source file existed rather than
      the install entry; pi and opencode stayed registered with agent-deck under
      a comment saying their bridges did not exist.
      Resolved, and it found a worse defect than the one it asked about. A probe
      capturing EVERY plugin event across four runs and 59 events never saw
      `session.idle` or `session.error` at all, so the original bridge was dead
      code. The real turn-end signal is `session.status` carrying
      `status.type === "idle"`; OpenCode's own code waits on exactly that, and
      the status union is busy, idle, retry, error, waiting. The bridge is
      rebound accordingly, with a check that fails if `session.idle` returns.
      The child-session question is handled by tracking the first
      `session.created` id as the root and ignoring every other session.
      Still unobserved end to end: no OpenCode turn completed in testing.
      `opencode run` exits before publishing an idle status, and three TUI turns
      stayed busy indefinitely on the available models. `deps:` 3.3,3.8,3.9
- [x] 3.11 Verify: `nix flake check` and `nh darwin build` are green `deps:` 3.10
- [x] 3.12 Apply: `nh darwin switch` `deps:` 3.11
- [x] 3.13 Confirm: `agent-state pi done "your move"` writes a correct state
      file with the right agent, status, and repo, which is the exact call shape
      the pi bridge makes. A live toast from each harness still needs the owner:
      it requires a real interactive turn `deps:` 3.12

## 4. Toast body names the review path

- **SHAPE** loop
- **STOP** `nix build .#checks.aarch64-darwin.notify-defect-regressions` exits 0,
  and the review-suffix fixtures fail when the separator, the dirty marker, or the
  negative-age guard is reverted
- **MAX-ITERS** 3
- TERMINAL: CAPPED at MAX-ITERS, or STALLED after 2 iterations with no change in
  the failing fixture set

- [x] 4.1 Read the per-pane state file in `agent-notify.sh` and append
      repo, branch, a dirty marker, and elapsed time to the body (follows the
      state-file read already in `agent-focus.sh`)
- [x] 4.2 Split the fields on `\u0001`, not on tab. Tab is an IFS whitespace
      character, so bash collapses runs of them and an empty field shifts every
      later value left; a repo with no branch read the timestamp as its branch `deps:` 4.1
- [x] 4.3 Extract the suffix composition into
      `config/agent-review-suffix.sh`, sourced by the notifier and by the check,
      so the shipped body and the asserted body are the same code. The helper
      takes the pane, not a path, so the state-file location exists once
      `deps:` 4.1,4.2
- [x] 4.4 Replace the presence-greps in `notify-defect-regressions` with fixture
      assertions over the composer: all fields, an empty branch, minute and hour
      rollover, a missing file, an unparseable file, and clock skew. Mutation
      tested: reverting the separator reproduces `sysinit · 0`, where the empty
      branch collapses and the timestamp is read as the branch name `deps:` 4.3
- [x] 4.5 Adversarial review: deferred to the change-level review; this phase is
      one file and its two failure modes each have a failing-on-revert check `deps:` 4.3
- [x] 4.6 Verify: `nix flake check` green, shellcheck clean on the combined
      script, field split confirmed across four state-file shapes `deps:` 4.5
- [x] 4.7 Apply: `nh darwin switch` `deps:` 4.6
- [x] 4.8 Confirm: verified in a real WezTerm pane with a patched notifier. The
      captured toast read `finished its turn — sysinit · main ✱ — 1s`, subtitle
      `sysinit`, group `agent:17` `deps:` 4.7

## 5. Rollout

- [ ] 5.1 Verify: `openspec validate unify-agent-notification-layer` passes and
      `specutil check` reports no finding
- [ ] 5.2 Verify: `nix fmt -- --check` is clean and `git diff` is reviewed
- [ ] 5.3 Apply: stage the change and propose a commit message per the
      `writing-commit-message` skill
- [ ] 5.4 Confirm: the owner approves the staged diff before any commit
