## 1. Agent state bus (capability: agent-state-bus)

- [x] 1.1 Factor the shared session·repo·pane identity resolution out of
  `agent-notify.sh` into a sourced helper (new
  `modules/home/programs/llm/config/agent-identity.sh`, or a shared function
  block) covering WezTerm-workspace lookup, seshy-cwd fallback, and git
  repo/branch/dirty/worktree derivation. Follows the resolution already inlined
  in `agent-notify.sh`.
- [x] 1.2 Update `agent-notify.sh` to consume the shared helper (behavior
  unchanged; no duplicated resolution).
- [x] 1.3 Extend `agent-state.sh` to write
  `~/.local/state/agents/panes/<WEZTERM_PANE>.json` atomically (temp file +
  `mv`) alongside the existing OSC emit, with the enriched payload
  (`pane,session,repo,branch,dirty,worktree,agent,status,reason,since`) built
  via `jq` for correct JSON escaping. Keep best-effort posture: no
  errexit/nounset/pipefail, always `exit 0`, no-op without `WEZTERM_PANE`.
- [x] 1.4 Add best-effort state-file removal on a terminal transition. Refined
  during apply: `done` ("your move") is itself an attention state external
  consumers must see, so it is NOT removed — the file is written for every
  status including `done`. Removal fires on a dedicated `exit` status wired to
  Claude's `SessionEnd` hook; Codex has no SessionEnd, so its files are reclaimed
  by readers' live-pane pruning (correctness never depends on cleanup running).
- [x] 1.5 Wire the new helper into `notify.nix` (ensure `agent-state`'s
  `runtimeInputs` include `jq`, `git`, `coreutils`, `wezterm`; install/source
  the shared helper). Follows the existing `writeShellApplication` wiring for
  `stateScript`. (Helper concatenated into both scripts' `text` at build time —
  no runtime source path, shellcheck validates the combined script.)
- [x] 1.6 Verify: `nix flake check` + `nh darwin build` green.
- [x] 1.7 Confirm: after a temporary local run of `agent-state` with a fake
  `WEZTERM_PANE`, a valid JSON file appears under
  `~/.local/state/agents/panes/` and parses with `jq`. (Verified: correct field
  types, quotes/newlines in reason escaped and single-lined, `exit` cleanup
  removes the file.)

## 2. Pane-level rollup (capability: agent-session-rollup)

- [x] 2.1 Extend `agent_session_states()` in
  `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua` to return a second value
  — an array of per-pane records (pane_id, window_id, tab_id, workspace, repo,
  branch, agent, status, reason, since, rank) — from the same single live-pane
  walk. `repo` is the in-memory cwd basename (new guarded `pane_repo` helper);
  `branch` is always "" on this render path (not derivable without a shell-out —
  the state-file bus carries the authoritative branch/dirty). Existing callers
  (`worst_agent_session`, `wm.get_choices`) take only the first return, unchanged.
- [x] 2.2 Add `worst_agent_pane()` selecting the highest-precedence actionable
  pane (`waiting > done > working`; idle held non-actionable), oldest `since` on
  ties, returning the per-pane record (pane_id + window_id + tab_id + workspace)
  or nil. Added `activate_agent_pane()` helper (mux tab/pane activate +
  SwitchToWorkspace) for the jump consumers.
- [x] 2.3 Verify: `nix flake check` + `nh darwin build` green (luajit
  `loadfile` syntax check + full closure build, no errors).

## 3. Jump navigation (capability: wezterm-agent-jump)

- [x] 3.1 Add `SUPER+g` calling `worst_agent_pane()` and activating it
  (activate tab + pane via mux, then SwitchToWorkspace when it differs); no-op
  when nil. Bound in `ui.lua` (not keybindings.lua) with the same locked-mode
  passthrough as the `SUPER+s` switcher, because it needs the rollup helpers in
  scope — keybindings.lua is a separate module that can't see ui.lua's locals.
  (`CTRL+g` locked-mode toggle is unaffected.)
- [x] 3.2 Add `SUPER+SHIFT+g` opening an `InputSelector` of all actionable panes
  (session · repo · agent · reason · age), precedence-ordered; selecting one
  activates it via the same helper. A since-closed pane resolves to nil in
  `wezterm.mux.get_pane` and no-ops. Bound alongside `SUPER+g` in ui.lua.
- [x] 3.3 Verify: `nh darwin build` green.
- [ ] 3.4 Confirm (human, live): with a blocked agent in another tab, `SUPER+g`
  lands on it; `SUPER+SHIFT+g` lists blocked panes and jumps on pick.

## 4. Per-tab state indicator (capability: per-tab-agent-state)

- [x] 4.1 Flipped `tabs_enabled = true` and prepended a `tab_agent_indicator`
  function component to tabline's `tab_active`/`tab_inactive` sections (defaults
  mirrored from the plugin's config.lua so the stock index/cwd/process still show
  the tab's short repo/cwd). The component reads `tab.active_pane.user_vars
  .agent_state`, parses the `status|reason|since|agent` payload, and returns the
  state icon (`◔/●/✔/○`) + agent label; returns "" (plain title) when absent or
  malformed. Emits a bare string, so the icon inherits the tab's fg color — the
  glyph alone conveys state (no per-status color available via function
  components). `tab_bar_at_bottom` and all `tabline_a/y/z` sections retained.
- [x] 4.2 Verify: `nix flake check` + `nh darwin build` green (luajit `loadfile`
  syntax check + full closure build, no errors).
- [ ] 4.3 Confirm (human, live): tab bar shows per-tab state icons; clicking a
  tab switches to it; statusline sections still render; no crowding regression
  (revert the flag if it does).

## 5. Richer switcher and statusline (capabilities: agent-aware-switcher, agent-aware-statusline)

- [x] 5.1 Enriched `wm.get_choices` rows: took the rollup's second (per-pane)
  return, aggregated per workspace into repo (cwd basename), agent-pane count,
  blocked (rank >= working) count with the worst status icon (e.g. `3 · 1◔`),
  and the worst pane's agent label — inserted between the session name and the
  existing reason/age. Branch + dirty are not derivable in-memory (design D4:
  the rollup stays fs/shell-free even here; the state-file bus carries them for
  out-of-WezTerm consumers), so they degrade out per the "missing git metadata"
  scenario. Stateless sessions keep bare rows; the pinned `default` entry and
  the urgency sort are untouched.
- [x] 5.2 Extended `agent_status()`: folded its only caller helper
  (`worst_agent_session`) inline so one mux walk feeds both the worst pick and
  the count; appends the total count of actionable (rank >= working) sessions,
  omitting the suffix when exactly one and rendering nothing (no worst, no `0`)
  when none — idle-only state no longer occupies the statusline.
- [x] 5.3 Verify: `nix flake check` + `nh darwin build` green (luajit `loadfile`
  syntax check + full closure build, no errors).
- [ ] 5.4 Confirm (human, live): `SUPER+s` rows show repo/branch/counts/icon in
  urgency order; statusline names the worst session and shows the count.

## 6. Actionable notifications (capability: actionable-notifications)

- [x] 6.1 Packaged `alerter` v26.5 as a darwin-only `stdenvNoCC.mkDerivation`
  (new `overlays/alerter.nix`, registered in `overlays/default.nix`): hash-locked
  `fetchurl` of the release zip (`sha256-EfY83cm7P4VU7Zt2JjKhIM+nvuBePAnWVzSCPgnSTxA=`),
  `unzip` into a scratch dir, `install -Dm755` the single arm64 Mach-O to
  `$out/bin/alerter`. `platforms.darwin` + `sourceProvenance = [ binaryNativeCode ]`
  so it never enters a linux closure. New pattern — design.md D2 (not in nixpkgs).
- [x] 6.2 Verified: `nix build …#darwinConfigurations.<host>.pkgs.alerter` builds;
  the binary is a `Mach-O 64-bit executable arm64` and `alerter --help` exits 0.
  Confirmed the v26.5 CLI is `--`-style (`--message/--actions/--title/--subtitle/
  --sound/--group/--app-icon/--content-image/--timeout/--json`), NOT the classic
  `-appIcon`. (The interactive Accept/Deny run is the human's live step, 7.3.)
- [x] 6.3 Added `agent-prompt.sh` (concatenated with the shared identity resolver +
  a baked `RELAY_ENABLED`/`NOTIFY_EXE` preamble in `notify.nix` as `promptScript`,
  exported `promptExe`). For genuine approval events it launches `alerter` detached
  with `Accept,Deny` actions, per-harness `--app-icon`/`--content-image`, per-agent
  `--group`, `session · repo` `--subtitle`, `--sound Funk`, `--timeout 300`; the
  hook backgrounds+disowns the waiter and returns immediately. Any miss (relay off,
  no alerter, non-approval reason, no keymap, no pane) degrades to the exact plain
  `agent-notify` toast (click-to-focus preserved) via `NOTIFY_EXE`.
- [x] 6.4 The detached waiter reads alerter's stdout and relays via `wezterm cli
  send-text --no-paste --pane-id`: `Accept`→approve keys, `Deny`→reject keys;
  `@TIMEOUT`/`@CLOSED`/`@CONTENTCLICKED`/empty are no-ops. Per-agent keymap
  (best-effort, tunable): claude approve=`\r`/reject=`\033`, codex approve=`y`/
  reject=`n`; an agent with no keymap never takes the actionable path. Whole relay
  gated behind `sysinit.llm.notifications.actionableRelay` (new option, default
  false — the kill switch, baked into the script at build time).
- [x] 6.5 Wired `promptExe` into `claude.nix` Notification (`claude attention`) and
  `codex.nix` PermissionRequest (`codex approval`); threaded `config` into
  `notify.nix` at all three import sites (default/claude/codex). All existing
  `stateExe`/`focusExe`/click-to-focus and other-event `exe` commands left intact.
- [x] 6.6 Verified: `nix flake check` green (only pre-existing fzf-rename warnings);
  `nh darwin build` green (closure diff produced, no errors); `git diff` reviewed —
  scoped to the six llm config files + options + two overlay files.

## 7. Rollout (impactful actions)

- [x] 7.1 Verified: full `nix flake check` + `nh darwin build` green across all
  slices (phases 1–6 built into one closure, diff `-905 MiB`, no errors);
  `openspec validate build-agent-state-bus-and-surfaces` passes; `git diff`
  reviewed. New/changed files staged with `git add -N` so the flake sees them
  (untracked files are invisible to flake eval); nothing committed.
- [x] 7.2 Apply (impactful): `nh darwin switch` (mutates the live system).
  Applied — system generation flipped to `system-1029` (`/run/current-system`
  → `cih4s6gbw8qq…`). One-time unblock: newer Homebrew's `HOMEBREW_REQUIRE_TAP_TRUST`
  refused the `slp/krunkit` tap's `virglrenderer` formula; the activation context
  runs `brew` WITHOUT `XDG_CONFIG_HOME`, so trust had to be written to
  `~/.homebrew/trust.json` (not `~/.config/homebrew/trust.json`) via
  `env -u XDG_CONFIG_HOME brew trust slp/krunkit && … --formula slp/krunkit/virglrenderer`.
  Post-switch: live `~/.claude/settings.json` now carries the new hook set
  (`Notification` → `agent-prompt claude attention …`), and `alerter-26.5`
  (Mach-O arm64) is on the wrapper PATH. `RELAY_ENABLED=0` baked in (kill switch
  off by default).
- [ ] 7.3 Confirm (human, live): state files under
  `~/.local/state/agents/panes/`; `SUPER+g`/`SUPER+SHIFT+g` jump; per-tab icons;
  richer switcher/statusline; with the relay toggle on, Accept approves and Deny
  rejects in the target pane; toggle off restores click-to-focus only. Use the
  named kill switches for any slice that misbehaves.
- [x] 7.4 Apply (impactful, on explicit user direction only): commit
  (conventional, title-only) and `git push` to `main`. Done — two title-only
  conventional commits (`chore(openspec): archive surface-agent-session-state`,
  `feat(agents): cross-surface agent state bus and wezterm surfaces`), rebased
  onto `origin/main`, pushed (remote `9c04cce69`).
- [ ] 7.5 Confirm: ping the user that it is applied; note any deferred
  fast-follows (throwaway-tab weighting / `done` decay; neovim consumer in
  `sysinit.nvim`).
