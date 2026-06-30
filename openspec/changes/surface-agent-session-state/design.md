## Context

Three observability mechanisms already exist and do not talk to each other:

- **`agent-notify.sh`** (`modules/home/programs/llm/config/agent-notify.sh`) —
  fired by Claude `Notification`/`Stop` and Codex `PermissionRequest`/`Stop`
  hooks. It already resolves the full identity tuple we need: the pane
  (`WEZTERM_PANE`), the seshy session (via `wezterm cli list` → workspace, with a
  `~/.local/state/seshy/sessions/<name>` cwd-parse fallback), the repo (`git -C
  cwd rev-parse`), and a human reason (the harness's own `message`). It emits a
  toast and exits — the tuple is discarded.
- **`agent-deck`** (vendored plugin, `wezterm/default.nix:21`) — classifies each
  pane working/waiting/idle by **scraping pane text**. Fragile by construction:
  needed `patches/agent-deck-idle-detection.patch` (a `> text` false-idle) and a
  stale-entry pruner (`ui.lua:170`, because closed panes never decrement). Its
  count feeds `tabline_y` via `agent_status()` (`ui.lua:196`).
- **`events.lua:6`** — already handles `user-var-changed` for `wez_copy` /
  `wez_not`. The OSC `SetUserVar` → WezTerm receive path is paved here.

The session switcher (`ui.lua:513`, `wm.get_choices`) lists seshy sessions from
`sy list` column 1 and sets `label = name` — nothing else.

This design connects the authoritative producer (hooks) to the persistent
surfaces (switcher, statusline) using the user-var transport that already has a
receiver, and demotes the scraper to a fallback.

## Goals / Non-Goals

**Goals:**
- Per-session state visible without switching panes: state, reason, age.
- Authoritative state for the cases that cause pane-switching (waiting on
  approval, turn done) — sourced from hook events, not text scraping.
- Reuse `agent-notify.sh`'s identity resolution rather than re-deriving it.
- Zero new stale-state machinery: state must self-clean when a pane closes.

**Non-Goals:**
- Cross-surface/persistent state (file, `sy status`, ssh). WezTerm-only.
- Replacing `agent-deck` (kept as hookless fallback) or changing notifications.
- New keybindings, overlays, or per-turn history.

## Decisions

### D1. Transport: OSC 1337 `SetUserVar` to the pane tty (not a state file)

The emitter writes `\033]1337;SetUserVar=agent_state=<base64>\007` to `/dev/tty`.
WezTerm absorbs it into `pane.user_vars.agent_state`; the rollup reads it
in-process via `pane:get_user_vars()`.

- **Why:** `user_vars` are scoped to the pane and **discarded when the pane
  closes**. This structurally eliminates the count-never-decrements class of bug
  (`ui.lua:170` exists only to work around it for `agent-deck`). The receive
  handler already exists (`events.lua:6`). No fs polling, no GC, no write-race
  file locking.
- **Alternative — per-pane JSON state file** (`~/.local/state/agents/<pane>.json`,
  reader globs + intersects with live pane ids): **rejected** for now. It
  reintroduces exactly the stale-entry pruning problem `user_vars` avoid, adds a
  write path and atomic-rename concern, and its only advantage (readable by
  `sy status` / over ssh) is an explicit non-goal. Recorded as the natural
  Transport C extension if cross-surface reach is ever wanted.
- **Alternative — keep scraping (`agent-deck` only):** rejected as the primary;
  it cannot know *why* an agent is blocked (no reason string) and is the source
  of the existing fragility. Retained only as fallback (D4).

### D2. Value encoding: base64 of a single delimited line

`agent_state` value = `base64("<status>|<reason>|<since_epoch>|<agent>")`.
WezTerm requires the `SetUserVar` value to be base64; Lua decodes and splits on
`|`. Reason is squashed to one line and truncated (D5).

- **Why a delimited string over JSON:** the payload is four flat scalars; a
  pipe-split avoids a Lua JSON dependency in the hot `update-status` path and a
  jq encode in the best-effort shell hook. `|` is escaped out of the reason
  during squashing so it stays an unambiguous delimiter.
- **Alternative — JSON blob:** rejected; heavier on both ends for four fields,
  and `wezterm.json_parse` per pane per status tick is needless cost.

### D3. State machine: which hook stamps which state

| Hook (Claude)      | status    | reason source                          |
|--------------------|-----------|----------------------------------------|
| `UserPromptSubmit` | `working` | `"thinking"`                           |
| `PreToolUse`       | `working` | `"<tool>: <squashed tool_input>"`      |
| `PostToolUse`      | `working` | `"thinking"`                           |
| `Notification`     | `waiting` | harness `message` (the prompt itself)  |
| `Stop`             | `done`    | `"your move"`                          |
| `SessionEnd`       | (none — pane close clears it)          |

Codex stamps `waiting` on `PermissionRequest` and `done` on `Stop`; it has no
working-state hooks, so its `working`/`idle` come from the `agent-deck` fallback
(D4). The asymmetry is acceptable: `waiting`/`done` are the states that drive
pane-switching, and those *are* authoritative for both harnesses.

- **Why stamp `working` at all (vs. only waiting/done):** the reason string on
  `PreToolUse` ("Bash: nix flake check") is the difference between "something is
  working" and "*this* is working on *that*", and `PreToolUse` is already wired
  for the bash guard, so the hook point exists.
- **Alternative — only Notification/Stop (minimal):** rejected as the end state;
  kept as the Phase-1 shippable slice (see Rollout) but the full set is the
  target because `working`+reason is half the value.

### D4. Fallback precedence: user-var wins, else agent-deck

Per pane, the rollup trusts `agent_state` if present; otherwise it falls back to
`agent-deck`'s status for that pane (no reason, no age). Hooked agents get the
precise path; hookless agents (aider/cursor/opencode) still appear, coarser.

- **Why keep agent-deck:** not every agent has lifecycle hooks; dropping it
  would make those panes vanish from the surfaces. Recorded alternative —
  *remove agent-deck entirely*: rejected (regresses hookless coverage).

### D5. Rollup reduction: worst-wins, carry reason + age

Per session (workspace): `state = max(panes)` under `waiting > done > working >
idle`; `reason` and `since` come from the pane holding the winning state (oldest
`since` on ties, so age reflects the longest wait); `age = now - since`.
Reason is single-line-squashed (newlines/`|`→space, collapse ws) and truncated
(~40 chars) before it ever reaches a label.

- **Why worst-wins:** the switcher answers "where must I go" — one blocked agent
  makes the session blocked regardless of its siblings. `done` outranks
  `working` because "your move" is also owed action.
- **Alternative — most-recent-transition wins:** rejected; a fresh `working`
  tick would mask an older `waiting` and hide the thing needing attention.

### D6. Surfaces read one shared rollup

`agent_session_states()` builds the per-session map once. `agent_status()`
(`ui.lua:196`) is rewritten to render it (worst session named + age);
`wm.get_choices` (`ui.lua:513`) enriches each `label` from the same map. The
switcher's `sy list` shell-out stays switcher-only (it must not run on every
`update-status` tick).

## Rollout & Gating

Sequenced, each slice independently buildable:

1. **Emission + rollup (no visible change).** Add `agent-state.sh` +
   `notify.nix` export; wire hooks; add `agent_session_states()` helper that
   nothing renders yet. Gate: `nix flake check` green, `nh darwin build` green.
   Nothing user-visible can break.
2. **Switcher.** Enrich `wm.get_choices` labels. Gate: build green, then
   **user spot-check live** — open `SUPER+s` with a real blocked agent and
   confirm the row shows state/reason/age. This is also where OSC-to-tty under
   the alt-screen TUI is confirmed (the one thing build cannot prove).
3. **Statusline.** Rewrite `agent_status()` to name the worst session. Gate:
   build green + live glance.
4. **Apply.** `nh darwin switch` only after 1–3 build green and the diff is
   reviewed.

**Kill switch:** the emitter is best-effort and additive — if it misbehaves,
the hook lines can be removed (or the script no-ops) and the surfaces fall back
to `agent-deck` exactly as today. The rollup treats a missing/garbled user-var
as "no state", so a bad payload degrades to the current behavior, never a crash.

Default gate sequence (edit → `nix flake check` → `nh darwin build` → user
spot-check → `nh darwin switch`) is followed as-is; `nh darwin` is used rather
than `nh os` on this host.

## Risks / Trade-offs

- **OSC `SetUserVar` to `/dev/tty` under Claude's alt-screen TUI may not land or
  may smear the display.** → `SetUserVar` is an out-of-band OSC WezTerm consumes
  (not rendered), and the hook subprocess inherits the pane's controlling tty.
  Mitigation: write to `/dev/tty` specifically (not stdout, which the harness
  captures); guard the write so failure is a silent no-op; **confirm live in
  Rollout step 2** before relying on it. Mapped to a `tasks.md` checkpoint.
- **Hook not in the pane's foreground process group** (nested/backgrounded
  agent) → `/dev/tty` resolves to the wrong/no tty. → best-effort: no tty, no
  emit, fallback to agent-deck. No error surfaced.
- **`update-status` cost** (rollup every ~150ms). → pure in-memory user-var
  reads over live panes; cheap. The expensive `sy list` stays switcher-only.
- **Reason strings can be long/multiline** (`PreToolUse` Bash commands). →
  squash+truncate in the emitter so the label is always one short line.
- **Codex working/idle asymmetry** (no working hooks). → covered by agent-deck
  fallback; documented, not a regression.

## Migration Plan

1. Land emission + rollup (Rollout 1). Verify: `nix flake check` + `nh darwin
   build` green. No system mutation yet.
2. Land switcher + statusline (Rollout 2–3). Verify: build green; review
   `git diff`.
3. Verify before apply: diff reviewed, both builds green.
4. Apply: `nh darwin switch` (mutates the live system — human checkpoint).
5. Confirm: open `SUPER+s` with a blocked agent; row shows state·reason·age;
   statusline names the session; hookless agent still shows via fallback. If
   OSC-to-tty does not land, remove the hook lines (kill switch) — surfaces
   revert to agent-deck behavior, no rollback of unrelated state needed.

Rollback: the change is additive (new script, new hook array entries, label
string changes). Reverting the commit and `nh darwin switch` restores prior
behavior; no persisted state to clean up (user_vars are ephemeral).

## Open Questions

- Should `PostToolUse` re-stamp `working` or is that redundant with the next
  `PreToolUse`? (Leaning: stamp it, so a long post-tool think still reads as
  working rather than going stale on the last tool's reason.)
- Exact reason truncation width once rendered against real session-name lengths
  in the switcher — tune during Rollout step 2.
