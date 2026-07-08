## Why

Agent lifecycle state today lives only inside WezTerm's per-pane user-vars
(`agent_state`), readable only from WezTerm Lua. That was enough to surface
"which session is blocked" in the statusline and `SUPER+s` switcher, but it
caps the ceiling: neovim (a separate `sysinit.nvim` clone) and `sy status`
cannot read user-vars, notifications can only raise a pane rather than let you
act on it, and a blocked throwaway agent in another tab of the same session is
invisible. To make this feel like one agentic IDE spanning WezTerm, the agent
harnesses, neovim, and seshy, state needs to become a shared, cross-surface bus
that every surface — and every repo — can subscribe to, plus richer navigation
and notifications built on top of it.

This builds directly on the now-archived `surface-agent-session-state` change,
whose emitter (`agent-state.sh`), rollup (`ui.lua`), switcher, and statusline
are already live on `main`.

## What Changes

- **NEW `agent-state-bus`**: `agent-state.sh` gains a second transport — it
  writes a per-pane JSON state file at
  `~/.local/state/agents/panes/<WEZTERM_PANE>.json` (atomic temp+rename)
  alongside its existing OSC user-var emit. The payload is enriched with the
  resolved session, repo, git branch + dirty flag, worktree path, agent,
  status, reason, and `since`. The identity-resolution logic (wezterm workspace
  + seshy-cwd fallback, repo/branch) is factored into a shared helper so
  `agent-state.sh` and `agent-notify.sh` stop duplicating it. The file schema is
  documented as the public contract that neovim, `sy`, and neph consume. Stale
  files are the reader's problem (intersect with live pane ids); best-effort
  cleanup fires on `Stop`/session-end where a signal exists.
- **NEW `wezterm-agent-jump`**: `SUPER+g` activates the single worst blocked
  pane across all workspaces (switch workspace if needed → activate tab →
  activate pane); `SUPER+SHIFT+g` opens an `InputSelector` of every blocked
  pane (session · tab · agent · reason · age) to pick from. This makes a
  throwaway agent blocked in another tab reachable in one keystroke.
- **NEW `per-tab-agent-state`**: flip tabline's `tabs_enabled` on and render a
  per-tab component showing each tab's active-pane state icon (◔/●/✔/○) + agent
  + short repo/cwd. WezTerm tab titles are natively click-to-switch, so this is
  the clickable "which tab needs me" affordance, disambiguating tabs within a
  session.
- **NEW `actionable-notifications`**: replace `terminal-notifier` with
  `alerter` (vjeantet/alerter) on the permission/waiting path so the toast
  presents **Accept/Deny** buttons and blocks for the choice on stdout; a
  detached waiter relays the decision back into the exact pane via
  `wezterm cli send-text` (agent-specific approve/reject keystrokes). Keep the
  per-harness custom icons (via `-appIcon`/`-contentImage`), per-session
  `-group` collapsing, and `-sound`. Behind a config toggle; keystroke relay is
  best-effort and per-agent.
- **MODIFIED `agent-session-rollup`**: the rollup keeps per-pane detail
  (pane id, window, tab, workspace/session, repo, branch, agent, status,
  reason, `since`) and adds `worst_agent_pane()` returning the exact pane to
  activate. Still in-memory over live panes, still worst-wins, agent-deck
  fallback retained.
- **MODIFIED `agent-aware-switcher`**: `SUPER+s` rows gain repo, branch + dirty
  marker, pane count + blocked count (e.g. `3 · 1◔`), and agent icon, on top of
  the existing state icon / reason / age. Urgency sort and pinned `default`
  entry unchanged.
- **MODIFIED `agent-aware-statusline`**: `agent_status()` names the worst
  session and appends the total count of blocked sessions across all
  workspaces.

### Non-goals

- The neovim consumer (staline agent segment, `<leader>j` jump-to-blocked-pane,
  seshy/worktree awareness) lands in the separate `sysinit.nvim` repo as a
  follow-on change; it is explicitly out of scope here. This change only
  produces the bus it will read.
- No `sy status` change — seshy is an external Go binary; it becomes a consumer
  later.
- No neph.nvim wiring.
- No quota/usage statusline segment.
- No change to the existing notification click-to-focus path (`agent-focus.sh`)
  beyond swapping the notifier binary.
- No `done`-decay in the rank function yet (noted as a fast-follow if throwaway
  `done` prompts nag the rollup).
- `agent-deck` stays as the hookless fallback; not removed.

## Capabilities

### New Capabilities
- `agent-state-bus`: per-pane JSON state-file transport, enriched identity
  payload, shared resolution helper, and the documented cross-surface schema
  contract.
- `wezterm-agent-jump`: keybinds to jump to the worst blocked pane or pick from
  all blocked panes.
- `per-tab-agent-state`: per-tab clickable agent-state indicator in the tab bar.
- `actionable-notifications`: alerter-based Accept/Deny notifications that relay
  the decision back into the pane.

### Modified Capabilities
- `agent-session-rollup`: carry per-pane detail and expose `worst_agent_pane()`.
- `agent-aware-switcher`: richer rows (repo, branch, pane/blocked counts, icon).
- `agent-aware-statusline`: name worst session + blocked-session count.

## Impact

- **Affected code**:
  `modules/home/programs/llm/config/{agent-state.sh,agent-notify.sh,notify.nix,claude.nix,codex.nix}`,
  `modules/home/programs/wezterm/lua/sysinit/pkg/{ui.lua,keybindings.lua}`, and
  a new nix derivation packaging `alerter`.
- **New dependency (impactful)**: `alerter` is not in nixpkgs; it is packaged by
  fetching its pinned prebuilt darwin release binary (hash-pinned `fetchurl`,
  darwin-only). This is a vendored-binary addition and a human-verification
  checkpoint.
- **Behavioral risk (impactful)**: `actionable-notifications` injects keystrokes
  into a live agent TUI via `wezterm cli send-text`. This is agent-specific and
  fragile; it is gated behind a config toggle (the kill switch) and defaults
  can be conservative until confirmed live.
- **Progressive rollout**: each capability is independently buildable and
  reviewable. Natural slice order: (1) `agent-state-bus` file transport
  (additive, invisible), (2) `agent-session-rollup` pane detail, (3)
  `wezterm-agent-jump`, (4) `per-tab-agent-state`, (5) richer switcher +
  statusline, (6) `actionable-notifications` last (highest risk). Removing any
  one reverts to current behavior.
- **Gating signal**: `nix flake check` then `nh darwin build` (verify, no system
  change) before `nh darwin switch` (apply). The state-file write and every new
  surface are additive; the actionable-notification path is toggle-gated.
- **Impactful actions requiring human checkpoints in tasks.md**: packaging the
  vendored `alerter` binary, `nh darwin switch`, live confirmation of
  OSC-to-tty + user-var read under Claude's alt-screen TUI, keystroke-relay
  live confirmation, and `git push` to `main`.
