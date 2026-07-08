## Why

Navigation to "the thing that needs attention" is split across three keybinds today —
`SUPER+s` (seshy session switcher, workspace granularity only), `SUPER+g` (express jump
to the worst blocked pane), and `SUPER+SHIFT+g` (flat blocked-pane picker). They overlap
in intent but differ in granularity, so the user has to remember which key reaches which
depth, and `SUPER+s` in particular drops you on a workspace but not the blocked pane
inside it. The goal is one all-in-one picker — a navigable session tree
(session → tab → pane → agent state) where every node is a jump target and a
path-style filter (`sysinit/tests/codex`) collapses straight to the pane you want.

## What Changes

- **NEW** `session-tree-model`: a single full-mux walk that produces a
  workspace → tab → pane tree of ALL live panes (not just agent panes), decorating each
  pane with its `agent_state` user-var (status/agent/reason/since) where present. It is a
  superset of the existing agent-only rollup in
  `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua` (`agent_session_states()`),
  reusing the same user-var parse. Dormant seshy sessions (present in `sy list` but not in
  the live mux) fold in as collapsed leaf nodes.
- **NEW** `session-tree-switcher`: `SUPER+s` opens ONE `InputSelector` rendering the tree
  as indented box-drawing rows. A top "needs attention" zone lists the actionable panes
  (urgency-ordered, jump-direct) so the worst is on top the moment it opens; the full tree
  follows. Every row is selectable and level-aware on activation: pane → exact pane,
  tab → tab (+ workspace if remote), live workspace → `SwitchToWorkspace`, dormant seshy →
  the workspace-manager plugin's own switch+restore.
- **NEW** `session-tree-filter`: every node label embeds its full `session/tab/agent`
  slash-path plus quick-filter tokens (status word, agent name, repo) as matchable text,
  so fuzzy-typing `sysinit`, `sysinit/tests`, `sysinit/tests/codex`, or a token like
  `codex` / `waiting` narrows the flat list to that subtree / pane / class. This is the
  contract that makes filtering "play nicely" — without the embedded path, filtering to a
  leaf's ancestor names fails because a child row does not contain them.
- **NEW** `session-tree-jump`: the in-picker interaction model, taken from neovim idioms.
  Ships as a telescope/fzf-style **fuzzy picker** (type to filter the embedded path/tokens,
  Enter to jump) with **in-picker quick-filter Ctrl keys** — `Ctrl+B` blocked, `Ctrl+G`
  agents, `Ctrl+D` dormant, `Ctrl+A` all — implemented via a key table activated before the
  selector (Enter/Escape included so it never leaks). A leap/flash-style two-letter label
  jump was evaluated but rejected: it is mutually exclusive with the quick-filter keys (bare
  label selection bypasses the key-table pop). See design.md for the verified InputSelector
  constraints behind this.
- **MODIFIED** `agent-aware-switcher`: the `SUPER+s` binding is repointed from the plain
  workspace switcher to the tree switcher. Both `SUPER+SHIFT+g` (blocked-pane picker) and
  `SUPER+g` (express jump) are **removed** — agent navigation is now entirely `SUPER+s`
  (the tree's needs-attention zone + `Ctrl+B` blocked filter subsume the express jump).
  `SUPER+SHIFT+s` (smart_ssh "Choose Host" picker, `keybindings.lua:223`) is unchanged.

### Non-goals

- No neovim-side tree — the `sysinit.nvim` consumer is a separate repo/change.
- No change to the notification / `agent-focus` click path or the actionable relay.
- No new per-tab tabline work (already shipped in `build-agent-state-bus-and-surfaces`).
- No collapse/expand persistence — `InputSelector` is a flat fuzzy list; the tree is
  rendered, not a stateful widget.
- No change to `SUPER+g` express behavior or `SUPER+SHIFT+s` ssh.
- No quota/usage statusline segment.

## Capabilities

### New Capabilities
- `session-tree-model`: full-mux workspace→tab→pane traversal with per-pane agent-state
  decoration and dormant-seshy merge, in one walk.
- `session-tree-switcher`: the `SUPER+s` all-in-one tree picker with a needs-attention
  zone and level-aware activation dispatch.
- `session-tree-filter`: path-embedded labels enabling `session/tab/agent` hierarchical
  fuzzy filtering.

### Modified Capabilities
- `agent-aware-switcher`: `SUPER+s` repointed to the tree; `SUPER+SHIFT+g` removed.

## Impact

- **Code**: `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua` (primary — new tree
  walk, tree/label rendering, dispatch, keybind rework). No change expected to
  `keybindings.lua` beyond leaving `SUPER+SHIFT+s` intact.
- **Reuse**: builds directly on the live `agent_session_states()` rollup,
  `activate_agent_pane()`, `worst_agent_pane()`, `agent_state_rank`/`agent_state_icons`,
  and the workspace-manager plugin (`workspace-manager.wezterm`, fetched in
  `wezterm/default.nix:88`). No parallel infrastructure introduced.
- **Progressive rollout**: the three new capabilities land in dependency order —
  model first (pure data, verifiable by logging the tree), then the switcher/dispatch,
  then filter polish — each built and syntax-checked independently before the keybind
  flip.
- **Gating signal**: `nix flake check` + `nh darwin build` (luajit `loadfile` syntax
  check + closure) before the impactful `nh darwin switch`. The true `InputSelector`
  render, path-filter behavior, and dormant-session restore are confirmable only live.
- **Impactful actions** (human checkpoints in tasks.md): `nh darwin switch` (mutates the
  live system) and `git push` to `main`.
- **Reversibility**: additive — the prior `SUPER+s`/`SUPER+g` handlers can be restored by
  reverting the binding block; no state migration.
