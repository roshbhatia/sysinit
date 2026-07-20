## Why

Claude Code's experimental Agent Teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`,
already set in `modules/home/programs/llm/config/claude.nix:119`) runs each
teammate as a separate `claude` process and can lay them out in `tmux` panes
(`--teammate-mode tmux`). A live spike proved that when that tmux session is
attached in WezTerm control mode (`tmux -CC`), each teammate becomes a **native
WezTerm pane** and the existing agent-surface stack lights up per teammate with
**zero code changes** on the WezTerm side: the `agent_state` OSC 1337 user-var
that `agent-state.sh` already emits is forwarded verbatim by control mode and set
on the correct native pane. Today this only happens if the user hand-runs the
right `tmux -CC` incantation and knows to force `--teammate-mode tmux`. This
change makes that path a single transparent command and closes the one real gap
the spike found (the cross-surface file bus collides under tmux).

## What Changes

- **New `claude-team` launcher.** A Nix-generated command starts a dedicated
  control-mode tmux session on an isolated socket and runs `claude` inside it
  with teammate tmux mode forced, so teammates render as native WezTerm
  tabs/panes. Re-running attaches to the existing session for the same repo.
- **Dedicated, Nix-generated tmux profile** used only by `claude-team` (isolated
  socket `-L claude`, status bar off so WezTerm draws the tabs, mouse on). The
  user never edits or sees this config; it does not touch their normal tmux.
- **Explicit `teamMateMode = "tmux"` in `claude.nix`** so the mode is
  deterministic instead of relying on `auto` (which renders tmux-in-one-pane when
  not already inside a control-mode session — the degraded UX).
- **tmux-aware file-bus keying in `agent-state.sh`** so per-teammate JSON state
  files no longer collide on a single stale `WEZTERM_PANE` id. The OSC/user-var
  transport is unchanged (the spike proved it already works under tmux).

### Non-goals

- **No change to the OSC/user-var transport or the WezTerm Lua surfaces.** The
  spike proved `agent-state.sh`'s OSC emit, `ui.lua` `worst_agent_pane`
  (`SUPER+g`), the statusline rollup, and tab-title icons already work per
  teammate through `tmux -CC`. This change adds no Lua and no tmux
  `allow-passthrough` requirement.
- **No full out-of-WezTerm pane-accurate mapping under tmux.** A process inside a
  tmux window cannot learn its true native WezTerm pane id, so the file bus can
  prevent collision but cannot make neph/neovim/seshy resolve the exact native
  pane for a teammate. Accurate cross-surface mapping under tmux is out of scope
  and tracked as an open question.
- **No replacement of the existing native-mux agent flow.** Running a single
  `claude` in its own WezTerm pane (no team) is unaffected; this is strictly
  additive and opt-in via the new command.
- **No new teammate display mode.** We consume Claude's `tmux` teammate mode as
  shipped; we do not build a WezTerm-native teammate spawner.

## Capabilities

### New Capabilities

- `claude-teammate-tmux-workspace` — the transparent `claude-team` launcher, the
  dedicated tmux profile, and the deterministic `teamMateMode = "tmux"` config
  that together render Claude teammates as native WezTerm panes via control mode.

### Modified Capabilities

- `agent-state-emission` — extend the emitter so that, when running inside tmux
  (`$TMUX` set), the per-pane JSON state file is namespaced by the tmux pane id
  (`TMUX_PANE`) to avoid the stale-`WEZTERM_PANE` collision, while the OSC
  user-var emit stays unchanged.

## Impact

- **Affected code.** New launcher script + tmux profile wired in
  `modules/home/programs/llm/` (follows the `writeShellScriptBin` +
  `config/agent-state.sh` script pattern already in that module);
  `config/claude.nix` (one settings key); `config/agent-state.sh` (file-path
  keying only). Optional WezTerm keybinding in
  `modules/home/programs/wezterm/lua/sysinit/pkg/keybindings.lua`.
- **Depends on live behavior of a third-party experimental feature.** The whole
  design assumes `claude --teammate-mode tmux`, when launched inside a tmux
  session, spawns teammates in that ambient session rather than a fresh tmux
  server. This is unverified and is the first gating task; if it spawns its own
  server, the launcher approach must be re-scoped.
- **Progressive rollout.** Ships in independently verifiable slices: (1) confirm
  Claude's ambient-tmux behavior; (2) `claude.nix` mode key; (3) launcher + tmux
  profile; (4) file-bus keying. Each is reviewable and buildable alone.
- **Impactful actions requiring human checkpoints.** `nh darwin switch` (applies
  the launcher, tmux profile, and claude settings to the live system) is the only
  shared-state mutation; it is gated behind `nix flake check` + `nh darwin build`
  and a manual teammate smoke test. No network writes, no vendored-content
  updates, no schema changes.
- **Gating signal.** Standard dotfiles gate: edit → `nix flake check` →
  `nh darwin build` → user smoke test → `nh darwin switch`. The feature is
  opt-in by invoking `claude-team`; not invoking it changes nothing.
