## 1. Session tree model (capability: session-tree-model)

- [x] 1.1 Added `session_tree(sy_bin)` to `ui.lua` — one `wezterm.mux.all_windows()` →
  `win:tabs()` → `tab:panes_with_info()` walk building workspace→tab→pane nodes for ALL live
  panes, each decorated via the new shared `pane_agent_state(p, deck_states)` helper (factored
  out of `agent_session_states()`, which now reuses it — single source of truth for the
  user-var + agent-deck parse). New `pane_proc`/`tab_label` helpers derive the leaf/tab path
  segments best-effort. Whole walk pcall-guarded per the existing rollup posture.
- [x] 1.2 Dormant merge implemented in `session_tree` via the new `seshy_session_names(sy_bin)`
  helper (mirrors the switcher's `sy list` header-skip + first-column parse); sessions in
  `sy list` but absent from the live workspace set are appended as `dormant = true` leaf nodes.
  Degrades to live-only when `sy_bin` is nil or `sy list` errors/empty (both pcall'd). The
  pinned `default` is added by the switcher layer (slice 2), matching the existing design.
- [x] 1.3 Verified: `nix flake check` + `nh darwin build` green (luajit `loadfile` syntax check
  + closure, +6.16 KiB, closure `3bk1xwxg`). `session_tree` is defined but not yet called
  (unused local is not a build error); its live shape is eyeballed in slice 2's palette test
  rather than via an ephemeral log.

## 2. Tree switcher + dispatch (capability: session-tree-switcher)

- [x] 2.1 Added `session_tree_choices(tree, by_id)` in the wm block — a `⚠ needs attention`
  header + urgency-ordered actionable panes, then the workspace→tab→pane tree as indented
  box-drawing rows (`├─ │ └─`). Node kind encoded in `id`
  (`hdr:`/`attn:<pane_id>`/`ws:<name>`/`tab:<tab_id>`/`pane:<pane_id>`); `by_id` maps id → the
  record to act on.
- [x] 2.2 Added `session_tree_dispatch(win, pane, id, by_id)`: `pane`/`attn`/`tab` all resolve
  to `activate_agent_pane` (a tab carries its active pane id from slice 1's `active_pane_id`),
  `ws` → `SwitchToWorkspace`. Header rows and non-table records no-op; since-closed targets
  no-op via `activate_agent_pane`'s existing pcall guard.
- [x] 2.3 Resolved design D7: inspected `workspace-manager.wezterm` (ryanmsnyder,
  `/nix/store/nygqw0…-source`). Restore is NOT automatic on `SwitchToWorkspace` — the plugin
  calls its PRIVATE `state.restore_workspace_state(name, win)` inside the switcher callback,
  and `state` is not exported (init.lua exports only `workspace_switcher`,
  `switch_to_previous_workspace`, `next/previous_workspace`, `save_workspace`,
  `apply_to_config`, `get_switcher_legend`, `get_zoxide_paths`). No public
  switch-with-restore exists. Chosen: dormant → one-shot
  `SwitchToWorkspace{name, spawn={cwd=<seshy session dir>}}` (favors the "quickly jump" goal
  over a double-picker). Trade-off recorded in a code comment: a dormant session's saved
  wezterm pane LAYOUT is not restored (you land in the workspace at the correct cwd). NOT a
  hand-rolled resurrect. Surfaced to the user for sign-off.
- [x] 2.4 Added a temporary `Session tree (preview)` `augment-command-palette` entry calling
  `open_session_tree`; `SUPER+s` left on the current switcher for now.
- [x] 2.5 Verified: `nh darwin build` green (luajit `loadfile` + closure, `+11.5 KiB`, closure
  `msndd4md`).
- [ ] 2.6 Confirm (human, live): from the command-palette entry, the tree renders; selecting a
  pane jumps to the exact pane; a tab node activates its tab; a live workspace switches; a
  dormant session switches to its cwd (D7 one-shot; layout not restored). Since-closed
  selections no-op. (Requires `nh darwin switch` — batched with slice 4.)

## 3. Filter + jump interaction (capabilities: session-tree-filter, session-tree-jump)

- [x] 3.1 Added `match_suffix()` (+ `sanitize_seg()`): every row appends its full
  `session/tab/agent` slash-path plus status/repo tokens as contiguous, whitespace-stripped
  ASCII, trailing the visible tree text. Leaves carry their complete ancestor path so an
  ancestor-name filter keeps the descendant after parent rows drop (design D4/D5).
- [x] 3.2 `open_session_tree` now opens in label-jump mode (`fuzzy = false`) with a curated
  home-row-first `alphabet = "asdfghlqwertyuiopzxcvbnm"` (omits j/k, the widget's movement
  keys). Needs-attention + live panes are emitted first so they get the earliest labels
  (design D3/D9); dropped the no-op header row (attention rows are ⚠-prefixed instead). `/`
  fuzzy toggle left as WezTerm's default — no `ctrl+f` attempt (design D2).
- [x] 3.3 Verified: `nh darwin build` green (luajit `loadfile` + closure, `+13.6 KiB`).
- [ ] 3.4 Confirm (human, live): the picker opens showing jump labels; typing a label jumps;
  `/` enters filter; typing `sysinit/tests/codex` narrows to that pane and `codex`/`waiting`
  filter to a class; confirm whether >35 nodes get multi-char labels (relaxes D9 if so).

## 4. Keybind flip + rollout (capability: agent-aware-switcher; impactful)

- [x] 4.1 Repointed `SUPER+s` to `open_session_tree` (kept the `keybindings.locked_mode`
  passthrough); made the palette entry permanent (`Session tree`, alongside the plain
  workspace switcher). Removed the `SUPER+SHIFT+g` blocked-pane picker binding. `SUPER+g`
  express and `SUPER+SHIFT+s` ssh (`keybindings.lua:223`) untouched.
- [x] 4.2 Verified: `nix flake check` clean + `nh darwin build` green (`+11.6 KiB`). `git
  status`/`diff` scoped to `ui.lua` (plus the untracked openspec change dir).
- [x] 4.3 Applied: `nh darwin switch` — system generation flipped to `pa37bny4`; live
  `ui.lua` carries `open_session_tree` and the old `SUPER+SHIFT+g` "Jump to blocked agent"
  picker is gone (grep count 0). Dormant confirmed as one-shot per user sign-off (no rework).
- [ ] 4.4 Confirm (human, live): `SUPER+s` opens the tree; label-jump + `/` path-filter work
  (`sysinit/tests/codex`); dormant session switches to its cwd; `SUPER+SHIFT+g` no longer
  opens a picker; `SUPER+g` and `SUPER+SHIFT+s` behave exactly as before. Kill switch = revert
  the ui.lua binding block.
- [x] 4.5 Applied (user-directed): committed (conventional, title-only) and pushed to `main`.
- [ ] 4.6 Confirm: ping the user that it is applied; note deferred fast-follows (neovim-side
  tree in `sysinit.nvim`; smooth dormant layout-restore if the plugin later exposes a public
  switch-with-restore; confirm multi-char jump labels beyond 35 nodes to relax D9).
