## Context

Claude Agent Teams runs each teammate as a separate `claude` process. Its
`--teammate-mode tmux` lays teammates out with native `tmux` commands. WezTerm's
tmux control mode (`tmux -CC`) reflects each tmux window/pane into WezTerm's own
mux as a native tab/pane.

This repo already ships an agent-surface stack built on WezTerm's **native** mux,
fed by `agent_state` OSC 1337 user-vars:

- Emitter: `modules/home/programs/llm/config/agent-state.sh` (OSC user-var +
  per-pane JSON file bus).
- Rollup + jump: `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua`
  (`pane_agent_state`, `agent_session_states`, `worst_agent_pane` at line 417;
  `SUPER+g` / `SUPER+SHIFT+g`).
- Existing specs: `agent-state-emission`, `agent-session-rollup`,
  `agent-aware-statusline`, `agent-aware-switcher`.
- Agent Teams already enabled: `config/claude.nix:119`
  (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"`), teammate mode currently unset
  (defaults to `auto`).
- tmux is managed at `modules/home/programs/tmux.nix`.

A live spike (WezTerm `0-unstable-2026-07-07`, tmux `3.7b`) established the load-
bearing facts, so this design extends the existing stack rather than paralleling
it:

1. tmux control mode forwards a bare OSC 1337 `SetUserVar` verbatim in its
   `%output` stream, with `allow-passthrough off`. Captured GUI-side: WezTerm set
   `agent_state` on the native pane from an unmodified emit.
2. Routing is correct: two tmux windows set state on two distinct native panes
   (`native_pane=1` vs `native_pane=2`).
3. Inside a control-mode session, every window inherits one stale `WEZTERM_PANE`
   value, so the file bus collides while the OSC path does not.

## Goals / Non-Goals

**Goals.**

- One transparent command (`claude-team`) that yields native-WezTerm teammate
  panes, no manual tmux.
- Deterministic teammate mode so the good UX is not left to `auto`.
- Keep the existing WezTerm agent surfaces working per teammate with no Lua
  change.
- Stop the file bus from corrupting/colliding under tmux.

**Non-Goals.**

- Native-pane-accurate file-bus mapping for out-of-WezTerm consumers under tmux
  (a tmux-inner process cannot learn its true native pane id).
- Any change to the OSC transport, `allow-passthrough`, or WezTerm Lua.
- A WezTerm-native teammate spawner; we consume Claude's tmux mode as shipped.

## Decisions

### Decision 1 — Dedicated tmux socket + generated profile, not the user's tmux

`claude-team` uses `tmux -L claude` with a Nix-generated config file, isolated
from the user's interactive tmux.

- **Alternative rejected — reuse the default socket / user config.** It would mix
  team sessions into the user's session list, inherit their prefix/keybindings
  and status bar, and require forcing `status off` on their real tmux. Isolation
  keeps the feature removable and side-effect-free (`agent-state-emission`'s
  "user's tmux untouched" scenario).

### Decision 2 — Force `teamMateMode = "tmux"`, not `auto`

Set the mode explicitly in `claude.nix`.

- **Alternative rejected — leave `auto`.** `auto` picks tmux when tmux is on
  PATH, but when Claude is not already inside a control-mode session it renders
  teammates as tmux panes inside one WezTerm pane — nested-mux keybindings, no
  native tabs. Explicit `tmux` + launching inside `-CC` makes the native path
  deterministic.

### Decision 3 — Leave the OSC/user-var transport unchanged

Ship no change to `agent-state.sh`'s OSC emit and require no `allow-passthrough`.

- **Alternative rejected — wrap the OSC in tmux passthrough (`\033Ptmux;…`) and
  enable `allow-passthrough`.** The spike proved the bare emit already reaches
  WezTerm through control mode; wrapping adds an emitter branch and a tmux-server
  setting for no gain. Rejected as unnecessary complexity.

### Decision 4 — File bus: namespace by `TMUX_PANE`, accept degraded mapping

Under `$TMUX`, key the per-pane JSON file on `TMUX_PANE` to prevent collision;
do not attempt to resolve the true native WezTerm pane id.

- **Alternative rejected — resolve the native pane id inside tmux.** A process in
  a tmux window has no clean way to learn which native WezTerm pane hosts it; a
  control-mode round-trip to discover it is disproportionate. Collision-avoidance
  is the honest, bounded fix; full mapping is an Open Question.
- **Alternative rejected — leave the file bus as-is.** All teammates overwrite
  one `9.json`, corrupting the bus for neph/neovim/seshy and for the real pane 9.

## Rollout & Gating

Sequenced slices; each builds and is verifiable alone. Default dotfiles gate:
edit → `nix flake check` → `nh darwin build` → user smoke test → `nh darwin
switch`. The whole feature is opt-in by running `claude-team`.

1. **Gate 0 — verify the third-party assumption first (no code).** Manually run
   `tmux -CC new-session` then `claude --teammate-mode tmux`, spawn 2 teammates,
   and confirm they appear as native WezTerm panes in the ambient session
   (`wezterm cli list`) and that `SUPER+g` reaches a blocked teammate. If Claude
   spawns its own tmux server instead, STOP and re-scope — the launcher is moot.
2. **Slice 1 — `claude.nix` mode key.** Add `teamMateMode = "tmux"`. Verify
   rendered settings; no behavior change until launched inside `-CC`.
3. **Slice 2 — launcher + tmux profile.** Add the `claude-team` command and the
   generated tmux config. Verify native panes appear.
4. **Slice 3 — file-bus keying.** Add `TMUX_PANE` namespacing to
   `agent-state.sh`. Verify two teammates write distinct files; non-tmux path
   unchanged.
5. **Apply.** `nh darwin switch` after build is green and the smoke test passes.

**Kill switch / gate:** the feature is inert unless `claude-team` is invoked;
`teamMateMode` only matters once a team is spawned. Reverting the launcher and
the mode key restores prior behavior with no residue (dedicated socket, no user
tmux mutation).

## Risks / Trade-offs

- **[Claude spawns its own tmux server, not the ambient session]** → Gate 0
  verifies this before any code lands; failure re-scopes rather than ships a dead
  launcher. Maps to task 1.x.
- **[WezTerm tmux control mode is upstream-experimental]** → The spike hit one
  `send-text`-into-control-pane error; interactive use was clean. Mitigation:
  document the known rough edge; the feature degrades to Claude's in-process mode
  if control mode misbehaves (Claude still runs). Maps to the smoke-test task.
- **[Stale `WEZTERM_PANE` also weakens out-of-WezTerm consumers]** → We scope the
  fix to collision-avoidance and record accurate mapping as an Open Question;
  in-WezTerm surfaces (the marquee features) are unaffected.
- **[`teamMateMode` key name/shape drift in an experimental feature]** → Verify
  the exact key against a live `/config` after switch before trusting it; treat
  like other experimental Claude keys in this repo.

## Migration Plan

1. Verify Gate 0 (ambient-tmux behavior). Confirm before writing any Nix.
2. Add `teamMateMode = "tmux"` to `claude.nix`. Verify `nix flake check` +
   rendered settings carry the key. Confirm no unknown-key rejection via
   `/config`.
3. Add the launcher + tmux profile. Verify `nh darwin build` green; smoke-test
   `claude-team` shows native teammate panes. Confirm `SUPER+g` reaches a blocked
   teammate.
4. Add `TMUX_PANE` file keying to `agent-state.sh`. Verify two teammates produce
   two JSON files; confirm the non-tmux path is byte-identical.
5. Apply with `nh darwin switch`. Confirm the command works on the live system;
   confirm reverting leaves the user's tmux untouched.

Rollback: remove the launcher, the tmux profile, and the mode key; the file-bus
keying change is backward-compatible (non-tmux name unchanged) and can stay or be
reverted independently.

## Open Questions

- Does `claude --teammate-mode tmux`, launched inside a `-CC` session, reliably
  reuse that ambient session across Claude versions? (Gate 0; re-verify on
  upgrades.)
- What is the exact settings key/shape for the teammate mode
  (`teamMateMode` vs `--teammate-mode` only)? Confirm against the live binary
  before trusting the Nix key.
- Can out-of-WezTerm consumers ever resolve the true native WezTerm pane for a
  teammate under tmux, or should they read `agent_state` user-vars via
  `wezterm cli` instead of the file bus? Deferred.
- Should `claude-team` bind to a WezTerm key (e.g. `SUPER+SHIFT+t`) in
  `keybindings.lua`, or stay a shell command only? Deferred to first use.
