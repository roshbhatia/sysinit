## Context

The notification layer already exists and mostly works. `notify.nix` builds
four shell applications from four authored scripts: `agent-notify`,
`agent-prompt`, `agent-state`, and `agent-focus`. A shared identity resolver,
`agent-identity.sh`, is concatenated into two of them at build time so they
cannot disagree about which session a pane belongs to. That structure is sound
and this change keeps it.

What is missing is a rule about who is allowed to raise a toast. Three other
producers grew up beside `agent-notify`:

- `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua:105` sets
  `notifications.enabled = true` on the agent-deck plugin for seven harnesses.
- `modules/home/programs/llm/config/pi.nix:20` vendors upstream `notify.ts`,
  which writes an OSC 777 sequence.
- OpenCode 1.18 exposes an `attention` block in `~/.config/opencode/tui.json`
  that this repository does not write, so its defaults apply. `attention` is
  declared in the TUI schema, not the Config schema; the Config schema sets
  `additionalProperties: false`, so writing it into the main config file would
  fail validation.

Patterns being reused:

- The notifier build block in `notify.nix:58` is the pattern for the new icon
  fetches and for any new script.
- `modules/home/programs/llm/config/extensions/openspec-status.ts` is the
  existing pattern for a repository-authored pi extension.
- `agent-focus.sh:24` already reads the per-pane state file to rebuild a
  notification group. The body-enrichment work extends that read rather than
  adding a second reader.

New pattern being introduced: a repository-authored OpenCode plugin. OpenCode
1.18 removed `experimental.hook`, so a shell hook is no longer available and a
plugin is the only surface. This is stated here because no OpenCode plugin
exists in the repository yet.

## Goals / Non-Goals

Goals:

- One producer raises every toast.
- Every configured harness reaches that producer or is declared uncovered.
- The four live defects are fixed and each has a check that would catch a
  regression.
- The toast body tells the human why to switch before switching.

Non-goals:

- The state-file schema, version field, and collection step. Those belong to
  `harden-agent-shell-terminal`.
- Command output mirroring. That belongs to `wezterm-command-console`.
- Replacing `alerter`, or delivering notifications on Linux.
- Adding a harness or changing any harness's model, provider, or permissions.

## Decisions

### D1. `agent-notify` is the single producer; other producers are turned off, not removed

The alternative is to keep several producers and coordinate them. That fails
because each producer has a different identity model. Agent-deck knows a pane
id and a scraped status but no session, repo, or reason. Pi's OSC 777 path
knows nothing at all. Only `agent-notify` resolves session and repo.

Turning a producer off rather than deleting it keeps its other output. Agent-
deck's scraping remains the statusline fallback for a hookless pane.

- Alternative rejected: route every producer into a common formatter. Rejected
  because the scraped and OSC paths carry no reason field, so the formatter
  would emit a degraded toast for those harnesses and the inconsistency would
  survive under a new name.

### D2. Pi and OpenCode bridge through thin shell-outs, not reimplementation

The pi extension and the OpenCode plugin do one thing: spawn `agent-state` and
`agent-notify` with the right arguments and discard the result. Classification,
dedup, identity, icons, and sounds stay in the shell scripts.

Pi's extension API exposes `session_start`, `tool_call`, `agent_settled`, and
`session_shutdown`, which map onto the existing `working`, `done`, and `exit`
vocabulary without inventing a new state.

The done event is `agent_settled`, not `agent_end`. Pi's bundled
`docs/extensions.md` states that `agent_end` fires while pi may still
auto-retry, auto-compact, or continue with a queued follow-up, and names
`agent_settled` as the event for a status integration. Wiring `agent_end`
would fire a done toast mid-run and reproduce the duplicate-notification
defect on the harness this change is adding.

- Alternative rejected: wire `agent_end` because it is the obvious turn-end
  event. Rejected because the vendor documentation explicitly directs status
  integrations away from it, and a premature done signal is the exact failure
  this change exists to remove.

- Alternative rejected: implement notification logic natively in TypeScript in
  each bridge. Rejected because it creates a third and fourth copy of the
  classification table, which is the exact failure this change exists to
  remove.

### D3. The notification group is keyed on the pane id

Today `agent-notify` groups on `agent-notify:<agent>:<context>` and
`agent-prompt` groups on `agent-prompt:<agent>:<context>`. `agent-focus`
removes only the first form. Two panes in one repository also collide on the
same group.

The group becomes `agent:<pane-id>`. One pane owns one slot. Any handler can
rebuild the name from the pane id alone, with no identity resolution.

- Alternative rejected: keep the two prefixes and teach `agent-focus` to
  remove both. Rejected because it leaves the pane collision unfixed and adds a
  second string that must stay in sync with two producers.

### D4. Dedup state is keyed on the pane id for the same reason

`agent-notify.sh:117` writes `$notif_dir/${agent}_idle`. Two claude panes share
one file. The key becomes `<pane-id>_<reason>`.

- Alternative rejected: key on agent and session. Rejected because two panes in
  one seshy session still collide, and the pane id is already in scope.

### D5. Body enrichment reads the state file, not git

`agent-notify` already depends on `git` through the identity resolver, but the
notification path runs inside a hook on the agent's critical path. The per-pane
state file already carries repo, branch, dirty, and `since`. Reading it is one
`jq` call against a local file.

- Alternative rejected: call `git` again from the notifier. Rejected because
  the resolver already paid that cost when the state file was written, and a
  second call doubles the hook's latency for no new information.

### D6. No menu bar surface

An earlier draft added a sketchybar widget over the same bus. Dropped at the
owner's direction: the statusline and the switcher already answer "which session
needs me", and a third surface would need its own liveness rule, its own stale
pruning, and a bar restart on every activation.

- Alternative rejected: ship the widget behind a toggle. Rejected because an
  unused surface still carries its pruning bug and its restart cost.

## Rollout & Gating

Four phases. Phases 1 and 2 are independently switchable. Phases 3 and 4 carry
ordering constraints that an earlier draft of this design got wrong.

1. Defect fixes in the shell scripts. Group key, dedup key, approval click,
   icons. No new files, no harness config change. Gate: `nix flake check`, then
   `nh darwin build`, then the owner raises one toast per fixed path.
2. Coverage set and agent-deck. Turn off agent-deck notifications only, and
   record all eleven harnesses as bridged, deferred, or no-surface. Pi's and
   OpenCode's own producers stay on through this phase. Gate: the owner
   confirms no duplicate toast for a claude wait, no missing statusline status
   for a scraped pane, and a build failure when a harness is in no set.
3. Pi and OpenCode bridges, each shipping in the same commit that turns off
   that harness's own producer. Requires
   `modernize-opencode-and-pi-config` phase 1, which creates the TUI config
   writer that `attention.notifications` needs. Gate: the owner starts one pi
   session and one OpenCode session and confirms a toast and a state file for
   each.
4. Toast body names the review path. Gate: a real toast in a WezTerm pane names
   the repository, the branch, the dirty marker, and the elapsed time.

The default sequence is edit, `nix flake check`, `nh darwin build`, owner
spot-check, `nh darwin switch`. No deviation.

Kill switch: phases 1, 2, and 4 revert with their commit. Phase 3 reverts by
restoring the harness's own producer in the same commit that removes the
bridge, because reverting only the bridge would leave that harness with no
producer at all.

## Risks / Trade-offs

- Pi extension API drift breaks the bridge on a pi upgrade. Mitigation: the
  bridge uses four documented events and swallows every error, so a rename
  degrades to no notification rather than a crashed session. Flagged as a
  human-verification checkpoint after phase 3.
- OpenCode plugin API is less documented than its config schema. Mitigation:
  phase 3 begins with a spike that confirms the event names against the
  installed 1.18.4 build before the plugin is written. If the events do not
  exist, OpenCode is recorded as uncovered and the phase ships pi only.
- Turning off agent-deck notifications silences seven harnesses that have no
  bridge: gemini, cursor, devin, copilot, amp, crush, and goose. Mitigation:
  each is recorded in the coverage set, and the statusline still shows the
  scraped status for those agent-deck covers. Gemini and devin are deferred,
  not surfaceless: both already render a `PreToolUse` hook file, so wiring them
  is future work rather than an impossibility. Flagged for owner confirmation
  in phase 2.
- Turning off pi's and OpenCode's own producers before their bridges land would
  silence them with no replacement, for as long as phase 3 takes. Mitigation:
  those two edits moved out of phase 2 and into phase 3, where each ships in
  the same commit as its bridge. A build assertion enforces the pairing.
- Icon fetches add three pinned network sources. Mitigation: the existing four
  already use this pattern and a hash drift fails the build loudly. Three of the
  seven uncovered harnesses get no glyph: simpleicons has no crush or goose
  entry, and its "AMP" icon sources from amp.dev, which is Google Accelerated
  Mobile Pages, not Sourcegraph Amp. Those three are recorded in an
  intentionally-generic list that a build assertion consumes.
- The sketchybar widget polls the state directory. Mitigation: it reads only
  local files and spawns no process, per its spec.

## Migration Plan

1. Verify: `nix flake check` passes on the current tree before any edit.
2. Apply phase 1, build, and switch. Confirm: an approval toast is dismissible
   and two idle panes both notify.
3. Verify: `git diff` shows only the three boolean flips and the pi extension
   list. Apply phase 2 and switch. Confirm: one toast per wait, and the
   statusline still names a scraped pane.
4. Verify: the OpenCode event-name spike succeeded. Apply phase 3 and switch.
   Confirm: a pi turn and an OpenCode turn each produce one toast and one state
   file.
5. Verify: the widget renders in a scratch bar config. Apply phase 4 and
   switch. Confirm: the bar restarts and the widget is empty when idle.

Rollback: revert the phase's commit and switch. No phase writes persistent
state outside `$XDG_STATE_HOME/agents/`, which is regenerated on the next
transition.

## Adversarial Review

Rubric: the spec scenarios in this change including every negative one, the
Decisions above, the Rollout & Gating phase gates, and the proposal Non-goals.

The deterministic half is mandatory. `specutil check` runs on every phase.

The critic half is default-on and owner-gated. The `adversarial-review` skill
elicits approve or deny; the owner may waive it for a small phase, recorded as
`Adversarial review: waived by owner`. When run, independent critics attempt to
break the phase with a concrete failing scenario that names a violated rubric
item. The author revises against surviving objections. The loop repeats until
no objection survives or K=4 rounds. Under Claude Code the critics are
in-process teammates. See the `adversarial-review` skill for the methodology.

## Open Questions

- Answered, and the first answer was wrong. `session.idle` exists in the
  binary's internal event-bus definitions but is NOT delivered to a plugin's
  `event` hook: a probe capturing every event across four runs and 59 events
  never saw it. The vocabulary a plugin receives is `session.created`,
  `session.updated`, `session.status`, `session.diff`, `message.updated`,
  `message.part.updated`, and a few registry events. Turn end is
  `session.status` with `status.type === "idle"`.
  The lesson: a string in a binary proves the symbol exists, not that the
  extension surface delivers it. Only a probe that captures everything can
  tell the difference.
- Should gemini and devin get a bridge, or stay on scraping only? Both render a
  `PreToolUse` hook file today, so both are recorded as deferred. The owner
  decides whether to wire them.
- Cursor and copilot are recorded as no-surface. Neither `cursor-agent --help`
  nor `copilot --help` names a hook mechanism, and a string scan of the
  installed copilot bundle finds none. An earlier draft claimed all four expose
  hooks; that was true only for gemini and devin.
- `alerter` is unmaintained upstream. No replacement is proposed here, but the
  single-producer rule makes a future swap a one-file change.
