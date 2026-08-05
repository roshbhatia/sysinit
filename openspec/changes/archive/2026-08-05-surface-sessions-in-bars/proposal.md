## Why

The session rollup exists only inside WezTerm. `ui.lua` computes, per seshy
session, the worst agent state, the repo, the pane count, and how long it has been
blocked, and it renders that in the statusline and in the `SUPER+s` tree. Outside
WezTerm nothing shows it, so switching away from the terminal loses the answer to
"which session needs me".

The macOS bar shows the front app and the aerospace mode. Neither says which
session is selected or what else is waiting. Linux has waybar and shows neither.

## What Changes

- Add `agent-sessions`, one command that prints the rollup as JSON: available
  sessions, the selected one, each session's status, repo, pane count, and blocked
  count. It reads the per-pane state bus under `~/.local/state/agents/panes/` and
  `sy list`, the same two sources `ui.lua` already reads.
- Publish the selected session with a heartbeat. WezTerm knows which workspace is
  active and a bar cannot ask it, so `ui.lua` writes `{ selected, heartbeat }` on
  its existing `update-status` tick. `agent-sessions` reports that selection as
  fresh, stale, or absent by comparing the heartbeat against now, so a bar can tell
  "no WezTerm running" from "no sessions" and never shows a stale selection as
  current.
- Add a sketchybar widget rendering the selected session and the count of sessions
  needing attention, beside the existing `front_app` chip. It appears only when
  WezTerm is the front app, per the request.
- Add the equivalent waybar module on Linux, reading the same command, so both
  platforms show one thing computed one way.

### Non-goals

- Adding tab support to the `SUPER+s` switcher. It is already there: the tree
  renders workspace, then tab, then pane, with per-tab agent state and per-tab
  activation. Tab creation (`SUPER+t`), relative and absolute activation, reorder,
  and rename via `PromptInputLine` all already exist, and the tab bar is always
  visible. Nothing in this change touches tabs.
- Making a bar interactive. Click-to-switch needs a path from the bar into
  WezTerm's mux and is its own change.
- Changing what `ui.lua` computes. The rollup logic is reused, not restated.
- Replacing the WezTerm statusline. It keeps its in-memory path, which is faster
  than shelling out on every tick.
- Any harness or notification change.

## Behavior

- `agent-sessions --json` exits 0 and prints an object with `selected`,
  `selection_state`, and `sessions`, where `selection_state` is one of `fresh`,
  `stale`, or `absent`.
- With no WezTerm running and no state files, it still exits 0 and reports
  `selection_state: absent` with an empty `sessions` list. A bar must never see a
  non-zero exit for the ordinary idle case.
- With a heartbeat older than its staleness window, `selection_state` is `stale`
  and `selected` is still reported, so a bar can dim rather than blank it.
- The command writes nothing. It is a pure read of the state bus and `sy list`.
- Its output agrees with the `SUPER+s` tree for the same state: same session names,
  same worst status per session. A fixture-driven flake check asserts this against
  written state files rather than a live mux.
- The sketchybar widget renders only when WezTerm is the front app, and renders the
  selected session name plus an attention count when one or more sessions are
  blocked.
- The waybar module renders the same two facts from the same command on Linux.
- Neither bar blocks on the command. Both have a timeout, and a timeout renders the
  absent state rather than a stuck chip.

## Impact

Affected code:
- New: `modules/home/programs/llm/runtime/agent-sessions.sh`, built by
  `runtime/default.nix` beside `agent-review`.
- New: a sketchybar widget under
  `modules/darwin/home/sketchybar/lua/sysinit/pkg/widgets/`.
- Modified: `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua` to write the
  selection plus heartbeat on its existing tick.
- Modified: `modules/nixos/home/desktop.nix` for the waybar module.
- New: a flake check under `checks/`.

Reuse:
- `agent-review` is the closest existing pattern: a read-only reporting command
  built in `runtime/default.nix`, keyed on the same state bus, exit code
  meaningful. `agent-sessions` follows it directly.
- The state bus at `~/.local/state/agents/panes/<pane>.json` and the liveness rule
  that intersects state files with live pane ids already exist and are reused, not
  reimplemented.
- The heartbeat idea is the mitigation the owner asked for, so a reader can
  distinguish stale from absent.

Impactful and irreversible actions:
- `nh darwin switch` installs the sketchybar widget, which restarts sketchybar.
- No network write, no vendored content, no schema change.

Gating signal:
- `nix flake check`, then `nh darwin build`, then the owner confirms the bar shows
  the right session, then `nh darwin switch`. The kill switch is removing the
  widget from the sketchybar item list, which leaves the command installed and
  harmless.
