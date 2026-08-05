## Context

The rollup already exists, in `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua`.
It groups per-pane agent state into per-session state, worst-wins, and renders it in
the statusline and the `SUPER+s` tree. Nothing outside WezTerm can read it, because
it is in-memory Lua inside the mux.

Two consumers need it: sketchybar on darwin, waybar on Linux. Neither can call into
WezTerm's Lua, so the rollup has to be readable from a process neither controls.

Two facts have different owners, which is the whole shape of this design. The
session set and each session's state are derivable from disk: the per-pane state bus
under `$XDG_STATE_HOME/agents/panes/` plus `sy list`. The *selected* session is not:
only the mux knows which workspace is focused.

Tabs are explicitly not in scope. The `SUPER+s` tree already renders workspace, then
tab, then pane, with per-tab agent state and per-tab activation, and tab creation,
activation, reorder, and rename are all already bound. That was verified before this
change was written, and the finding is recorded in the proposal's `Non-goals` rather
than being built again.

## Goals / Non-Goals

Goals:
- One command computes the rollup, and all three surfaces read it.
- A bar can distinguish a live WezTerm from one that quit leaving its last
  selection behind.
- A bar never renders an error as its steady state.
- macOS and Linux show the same two facts from the same source.

Non-Goals:
- Tabs. Already implemented; see the proposal.
- Click-to-switch from a bar. That needs a path into the mux and is its own change.
- Replacing the WezTerm statusline's in-memory path, which is faster than shelling
  out per tick.

## Decisions

### D1. A command, not a file the bars parse directly

`agent-sessions` owns the rollup logic. The bars call it and render its output.

- Alternative rejected: have `ui.lua` write the whole rollup to a JSON file that the
  bars read directly. Rejected because the session set and per-session state are
  derivable from disk without WezTerm, so putting them behind WezTerm would make a
  bar blank whenever the terminal is closed, when the correct answer is still
  available. Only the selection genuinely requires the mux, and only the selection
  goes through a file.

### D2. The selection carries a heartbeat

`ui.lua` writes `{ selected, heartbeat }` on its existing `update-status` tick.
`agent-sessions` compares that timestamp to now and reports `fresh`, `stale`, or
`absent`.

- Alternative rejected: write the selection with no timestamp. Rejected because
  "WezTerm quit an hour ago" and "WezTerm is running and this is current" are then
  the same bytes, so a bar shows the last-focused session forever. The owner
  identified this directly, and it is why the field exists.

### D3. Stale is dimmed, never hidden and never shown as current

A stale selection keeps its name and renders muted: `foreground_muted` in
sketchybar, a `.stale` CSS class in waybar.

- Alternative rejected: hide the chip when stale. Rejected because hiding is
  indistinguishable from having no sessions, which throws away the one thing the
  heartbeat bought. Showing it plainly is worse: it claims a dead mux's workspace is
  focused.

### D4. Always exit 0

`agent-sessions` exits 0 for every ordinary case, including no state at all.

- Alternative rejected: exit non-zero when there is nothing to report, so a caller
  can branch on it. Rejected because a bar polls this on a timer and "nothing to
  report" is the common case, so a non-zero exit would make both bars render an
  error as the steady state. A missing `jq`, a malformed state file, and an empty
  state dir all still print a valid empty report.

### D5. Poll, not subscribe

Both bars poll on a 2-second interval.

- Alternative rejected: push from the agent hooks into the bars. Rejected because it
  would couple every harness's hook to two bar implementations on two platforms,
  when the state bus already exists as the decoupling layer. 2s matches how fast the
  notifier reacts, so the chip is never conspicuously behind a toast.

### D6. The check drives fixtures, not a live mux

`checks/agent-sessions-rollup.nix` writes state files and asserts the output. It
deliberately runs without `wezterm` on PATH, which exercises the branch where the
live-pane set is unknown and the script trusts the files rather than dropping every
session.

- Alternative rejected: assert only that the command exits 0. Rejected because that
  is exactly the class of check this repository keeps finding broken: it would pass
  against a command that always printed an empty report. The check asserts the
  three selection states and the worst-wins ordering by content.

## Rollout & Gating

1. The command and the heartbeat, with the fixture check. Gate: `nix flake check`.
2. The two bar consumers. Gate: `nix flake check`, plus the waybar module evaluating
   into arrakis's config and its jq program producing correct output for both fresh
   and stale.
3. Rollout: `nh darwin build`, then the owner confirms the chip reads well, then
   `nh darwin switch`. That confirmation cannot be automated, because whether a bar
   is legible is a judgment.

Kill switch: remove the widget from `sketchybar/lua/sysinit/init.lua` and the module
from `modules-left`. The command stays installed and harmless.

## Risks / Trade-offs

- A guessed key or field name silently degrades rather than failing. This happened:
  `colors.foreground_secondary or colors.foreground_primary` named a key that does
  not exist, so stale would have rendered identically to fresh and the heartbeat
  would have bought nothing. Mitigation: no `or` fallback behind a key that must be
  right; the real key is `foreground_muted`, verified against `colors.lua`.
- jq scoping silently changes a filter's meaning. This happened: inside
  `.sessions[]`, a bare `.selected` resolves against the session object, so the
  filter never matched. Mitigation: bind `$sel` from the root, and test the
  evaluated program against real output rather than reading it.
- Polling every 2s per bar costs a process spawn. Mitigation: the command is jq over
  a handful of small files, and the WezTerm statusline keeps its in-memory path.
- A bar hangs if the command hangs. Mitigation: neither bar blocks; a failed or
  empty read renders the absent state.

## Migration Plan

1. Add the command, build it in `runtime/default.nix`, install it.
2. Add the heartbeat write to `ui.lua`'s existing tick.
3. Add the fixture check and mutation test it.
4. Add the sketchybar widget and the waybar module.
5. Verify: `nix flake check`, and arrakis evaluates.
6. Confirm: the owner reads the chip on a real bar.
7. Apply: `nh darwin switch`.

Rollback: `git revert` the widget commit. The command is inert without a consumer.

## Adversarial Review

The rubric is the proposal's `Behavior` criteria, the `Decisions` above, the
`Rollout & Gating` gates, and the proposal's `Non-goals`.

Two halves per the `adversarial-review` skill. `specutil check` is mandatory every
phase. The LLM critic loop is default-on and owner-gated, and a waiver is recorded
as `Adversarial review: waived by owner`. When it runs, independent critics attempt
to break the phase with a concrete failing scenario naming a violated rubric item,
the author revises against surviving objections, and the loop runs to a terminal
state. The skill scales the round cap and stops early on non-convergence or
fix-induced churn. A cap hit is reported as open objections, never as a pass.

The lens that matters here: a bar renders something plausible for every wrong
answer, so "it looks right" is not evidence. A critic should ask what input would
make the chip lie, and whether any check would notice.

## Open Questions

- Whether the attention count should exclude sessions whose blocked pane is merely
  `working`. Today any non-idle pane counts, so a long build inflates the count.
- Whether the sketchybar chip should be clickable to switch sessions. That is D-scope
  for a later change and needs a path into the mux.
