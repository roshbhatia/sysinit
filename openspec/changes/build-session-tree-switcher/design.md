## Context

WezTerm agent/session navigation is spread across three keybinds in
`modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua`: `SUPER+s` (the
`workspace-manager.wezterm` plugin switcher, workspace granularity), `SUPER+g`
(express jump to the worst blocked pane), `SUPER+SHIFT+g` (flat blocked-pane picker).
This design collapses them into one all-in-one `SUPER+s` session-tree picker.

It extends live, already-shipped machinery rather than inventing new infra:
- `agent_session_states()` (ui.lua ~), the single-walk agent rollup returning
  `(sessions, panes)` — reused and generalized to ALL panes.
- `activate_agent_pane(win, gui_pane, rec)` — the mux tab/pane activate + cross-workspace
  `SwitchToWorkspace` helper — reused verbatim for pane-node dispatch.
- `worst_agent_pane()`, `agent_state_rank`, `agent_state_icons` — the urgency model,
  reused for the needs-attention zone and ordering.
- The `workspace-manager.wezterm` plugin (ryanmsnyder, `wezterm/default.nix:88`) — its
  seshy `sy list` choices and session-restore-on-switch are reused for dormant sessions.
- WezTerm's built-in `wezterm.action.InputSelector` — the picker widget.

**Verified InputSelector capabilities** (wezterm.org/config/lua/keyassignment/InputSelector):
fields are `title`, `choices` (`{label, id}`), `action` (`(window,pane,id,label)`),
`fuzzy` (bool, default false), `alphabet` (default `"1234567890abcdefghilmnopqrstuvwxyz"`,
35 chars, omits j/k for movement), `description`, `fuzzy_description`. Default mode assigns
each row a quick-select label from `alphabet` (leap/flash-style jump); `/` enters fuzzy
mode (this toggle key is NOT configurable); the fuzzy matcher matches against each choice's
label text. The docs do NOT document custom key handlers / key_tables active inside an open
InputSelector, and do NOT document multi-character labels beyond the alphabet length.

## Goals / Non-Goals

**Goals:**
- One `SUPER+s` picker: workspace → tab → pane → agent-state tree, every node a jump target.
- A needs-attention zone on top so the worst blocked pane is reachable the instant it opens.
- Path-style hierarchical filtering: `sysinit`, `sysinit/tests`, `sysinit/tests/codex`.
- Leap-style label-jump as the default interaction; fuzzy filter one keystroke away.
- Dormant seshy sessions selectable (open + restore) from the same picker.
- Keep `SUPER+g` express and `SUPER+SHIFT+s` ssh unchanged; retire `SUPER+SHIFT+g`.

**Non-Goals:**
- Rebinding the fuzzy toggle to `ctrl+f` (WezTerm owns `/`; not configurable).
- Custom keypress "quick-filter" chips inside the selector (not supported by InputSelector).
- A bespoke overlay-pane picker UI (large lift; the built-in selector suffices).
- neovim-side tree, tabline changes, notification/relay changes, collapse/expand persistence.

## Decisions

**D1 — The "tree" is rendered indented rows in a flat InputSelector, not a widget.**
Each node is one `choices` entry; parent/child structure is conveyed by box-drawing
indentation (`├─ │ └─`) in the `label`. Alternative rejected: a custom overlay pane with a
real tree widget — far more code and maintenance for a picker WezTerm already gives us 90%
of. Alternative rejected: nested/expandable InputSelectors — InputSelector has no expand
state and no way to re-open at a node.

**D2 — Jump-first interaction: open in label mode (`fuzzy = false`), `/` to filter.**
The user asked for a `ctrl+f` "jump mode" with two-letter labels. InputSelector delivers
exactly that as its DEFAULT mode via `alphabet` — labels are already on-screen at open, so
no toggle key is needed to reach them (strictly better than a `ctrl+f` gate). Filtering is
`/` (fixed by WezTerm). Alternative rejected: `fuzzy = true` (open in filter mode, as the
workspace-manager plugin does) — that hides the jump labels behind a keystroke and inverts
the requested default. Alternative rejected: binding `ctrl+f` to toggle — the docs show the
toggle key is not configurable and no custom key runs inside the selector.

**D3 — A curated home-row `alphabet` for the jump labels.**
Override the default with a leap-like, home-row-first set (e.g. `asdfghlqwertyuiopzxcvbnm`
plus digits, still omitting the movement keys) so the easiest keystrokes land on the
top-of-list needs-attention nodes. Alternative rejected: the stock alphabet — leads with
digits, which are slower than home row for a jump gesture.

**D4 — Quick filters are matchable tokens embedded in the label, not keys.**
Since no custom keys can run inside the selector, each row's label carries, after the visible
tree text, its full `session/tab/agent` slash-path plus status word (`waiting`/`working`/
`done`), agent name, and repo. In `/` mode, typing `sysinit/tests/codex`, `codex`,
`waiting`, or a repo name filters via the fuzzy subsequence match. This is the fzf/telescope
idiom. Alternative rejected: multiple pre-scoped keybind entry points (e.g. a "blocked only"
key) — reintroduces the multi-key sprawl the user is collapsing.

**D5 — Self-describing rows so filtering survives tree flattening.**
Fuzzy filtering drops non-matching rows, orphaning indentation; a child row filtered by an
ancestor name must therefore CONTAIN that ancestor. Every leaf embeds its complete path
(D4), so `sysinit/tests/codex` matches the pane row even though `sysinit` and `tests` are
separate parent rows that get filtered out. The indentation is decoration for the unfiltered
view only.

**D6 — Node id scheme + level-aware dispatch.**
Choice `id` encodes kind+target: `attn:<pane_id>` (needs-attention duplicate),
`pane:<pane_id>`, `tab:<tab_id>`, `ws:<workspace>`, `dormant:<session>`. The `action`
callback parses the prefix and dispatches: `pane`/`attn` → `activate_agent_pane`-style exact
pane activation; `tab` → activate that tab (+ `SwitchToWorkspace` if remote); `ws` →
`SwitchToWorkspace`; `dormant` → the plugin's switch+restore (D7). Alternative rejected:
overloading `label` for dispatch — ids are the stable, format-independent key.

**D7 — Dormant-session restore reuses the plugin, never a hand-rolled resurrect.**
The whole point of `workspace-manager.wezterm` is session-layout persistence
(`session_state_dir`); our config sets `session_restore_on_startup = false` and relies on the
plugin restoring only when switched into via its switcher. A bare `SwitchToWorkspace{name}`
may therefore NOT restore layout. The dispatch for `dormant:` MUST route through the
plugin's own switch/restore entry point. The exact call is an Open Question to pin in
slice 2 (candidates: a public `switch`/`restore` fn on the plugin, emitting its selection
event, or — fallback — delegating dormant rows to the existing `wm.workspace_switcher()` as
a second step). Alternative rejected: reimplementing resurrect restore from
`session_state_dir` — duplicates the plugin's core job and will drift.

**D8 — One mux walk feeds both zones.**
A single `wezterm.mux.all_windows()` → `window:tabs()` → `tab:panes_with_info()` traversal
builds the full tree AND the needs-attention list (filter of rank ≥ working), mirroring the
existing single-walk discipline. Dormant sessions come from one `sy list` shell-out, diffed
against the live workspace set. Alternative rejected: separate walks per zone — redundant and
can disagree.

**D9 — Label mode covers the first ~35 nodes; fuzzy handles the tail.**
Multi-char labels beyond the alphabet length are undocumented, so quick-jump reliability is
only guaranteed for the first 35 rows. Order needs-attention + live panes first so the
common targets fall inside that window; the long tail (many dormant sessions) is reachable by
`/` filter. Alternative rejected: assuming two-letter labels scale infinitely — unverified.

## Rollout & Gating

Sequenced, each slice built + luajit-syntax-checked before the next; the keybind flip is last.

1. **Slice 1 — `session-tree-model`**: the full-mux walk + dormant merge, returning a plain
   tree structure. Pure data; no binding change. Gate: `nix flake check` + `nh darwin build`
   green (luajit `loadfile`), optionally `wezterm.log_info` the tree to eyeball shape.
2. **Slice 2 — `session-tree-switcher` + dispatch (incl. D7 resolution)**: render labels, id
   scheme, `action` dispatch, needs-attention zone. Still not bound to `SUPER+s` (expose via
   a temporary command-palette entry to test). Gate: build green + live palette smoke test.
3. **Slice 3 — filter + jump polish (`session-tree-filter` / jump)**: embed path/token match
   text, curated `alphabet`, `fuzzy=false`. Gate: build green + live `/`-filter and label-jump
   check.
4. **Slice 4 — keybind flip**: repoint `SUPER+s` to the tree; remove `SUPER+SHIFT+g`. Gate:
   build green, then the impactful `nh darwin switch`.

**Kill switch / reversibility**: additive and revertible — restoring the previous `SUPER+s`
and `SUPER+SHIFT+g` handler blocks reverts behavior with no state migration. `SUPER+g` and
`SUPER+SHIFT+s` are untouched throughout, so the express jump and ssh remain available even
mid-rollout.

## Risks / Trade-offs

- **Dormant restore may not have a clean plugin entry point (D7)** → Mitigation: slice 2
  investigates the plugin API first; fallback is delegating dormant rows to
  `wm.workspace_switcher()`. Human-verified checkpoint in tasks.md (live restore test).
- **`panes_with_info()` / mux API shape on this WezTerm version** → Mitigation: pcall-guard
  every mux call (existing helper posture); a missing field degrades the row, never errors.
- **>35 nodes weakens label-jump (D9)** → Mitigation: order actionable/live first; document
  that the tail is fuzzy-only. Human-verified checkpoint.
- **Fuzzy match includes box-drawing/format chars in the label** → Mitigation: keep the
  matchable path/token substring contiguous and ASCII so subsequence matching is predictable;
  live filter test (`sysinit/tests/codex`) is a checkpoint.
- **`nh darwin switch` mutates the live system** → Mitigation: gated last, after all slices
  build green; explicit human checkpoint in tasks.md.

## Migration Plan

1. Land slices 1–3 (no binding change) — verify each with `nh darwin build` (no system
   mutation) and, for 2–3, a live palette/selector smoke test.
2. **Verify** build green → apply slice 4 keybind flip → **`nh darwin switch`** (impactful)
   → **confirm** live: `SUPER+s` opens the tree, label-jump works, `/` path-filter narrows to
   a pane, dormant session restores, `SUPER+SHIFT+g` is gone, `SUPER+g`/`SUPER+SHIFT+s` intact.
3. Rollback: revert the ui.lua binding block to the prior `SUPER+s`/`SUPER+SHIFT+g` handlers
   and `nh darwin switch`. No persisted state to unwind.
4. **Verify** clean tree + **confirm** with user before `git push` to `main` (impactful).

## Open Questions

- **D7**: the precise `workspace-manager.wezterm` call for switch-with-restore of a named
  dormant session (public fn vs. event vs. fallback delegation) — resolved in slice 2.
- Does this WezTerm version assign multi-character jump labels beyond 35 rows? If yes, D9's
  constraint relaxes — confirm live in slice 3.
- Should the needs-attention zone also appear as inline agent rows in the tree (duplicated),
  or only at the top? Default: both (top for speed, in-tree for context); revisit if noisy.
