## 1. Dead tabline config removal (capability: session-tree-switcher)

- [x] 1.1 Removed the `tab_active` and `tab_inactive` blocks and `tab_agent_indicator`
  function from `tabline.setup` in `ui.lua` — all unreachable dead code.
- [x] 1.2 Verified: `nh darwin build` green. Applied: `nh darwin switch`
  (generation `i448aw5cbpf0ix7jrq05qa7z1ki4g4ix`).

## 2. Agent state prefix in tab title (capability: session-tree-switcher)

- [x] 2.1 Added agent-state icon prefix (`⟳` working / `◔` waiting / `✔` done) in
  `format-tab-title` by reading `pane.user_vars.agent_state` (plain table lookup,
  pcall-guarded). Idle state intentionally omitted.
- [x] 2.2 Verified: build green. Applied: `nh darwin switch`.
- [ ] 2.3 Confirm (human, live): start a Claude task; active tab shows `⟳` while
  working and `◔` when waiting for approval.

## 3. Notification dismiss on navigation (capability: agent-notification-system)

- [x] 3.1 Added `terminal-notifier -remove` at the top of `agent-focus.sh` —
  reconstructs the group string from the pane's state file, dismisses the toast
  immediately on click. Guards on `terminal-notifier` presence and state-file
  existence; falls through silently on any failure.
- [x] 3.2 Verified: build green. Applied: `nh darwin switch`.
- [ ] 3.3 Confirm (human, live): trigger a done notification (60+ second Claude task),
  click it; confirm toast disappears immediately rather than persisting to its timeout.

## 4. Codex session-start tracking (capability: agent-notification-system)

- [x] 4.1 Moved `agent-state codex working submit` to Codex's documented
  `UserPromptSubmit` hook. `PermissionRequest` now only represents approval/waiting
  state. Follow-up: removed the unsupported Codex `async` TOML key after 0.142.5
  warned that async hooks are not supported.
- [x] 4.2 Also fixed a bug in `agent-state.sh`: the `submit` case referenced `$since`
  before it was computed — moved `since=$(date +%s)` to before the case block.
- [x] 4.3 Verified: build green. Applied: `nh darwin switch`.
- [x] 4.4 Added Codex activation cleanup to move legacy `~/.codex/hooks.json` to
  `hooks.json.disabled*`, preserving the file while ensuring Codex loads hooks
  only from the Nix-managed TOML layer.
- [ ] 4.5 Confirm (human, live): quick Codex reply (< 60s from UserPromptSubmit to
  Stop) → no done notification; longer task (> 60s) → done notification fires.

## 5. Amp lifecycle hooks (capability: amp-lifecycle-hooks)

- [ ] 5.1 BLOCKED: Amp's settings reference (verified via `amp --help`) does not
  document a `hooks` key. The binary is compiled; no source available locally to
  confirm whether an undocumented `amp.hooks` is parsed. Resolve by checking Amp's
  changelog / GitHub issues for a hooks feature, or by testing with a trial
  `amp.hooks` entry and observing whether Amp logs a warning on startup.

## 6. agy (Antigravity) lifecycle hooks (capability: agy-lifecycle-hooks)

- [ ] 6.1 BLOCKED: Need to resolve agy config location and hook key names. Inspect
  `pkgs.antigravity-cli` wrapper / `agy --help` / `~/.config/agy/` to confirm
  config path and whether `onStop`/`onToolStart`/`onUserMessage` exist.

## 7. OpenCode lifecycle hooks (capability: opencode-lifecycle-hooks)

- [ ] 7.1 BLOCKED: OpenCode config schema (`https://opencode.ai/config.json`) does not
  appear to have a `hooks` top-level key in the current config (`opencode.json` keys:
  `$schema, autoupdate, formatter, instructions, keybinds, mcp, permission, plugin,
  provider, share, small_model, theme, tui`). The binary is compiled Go. Resolve by
  checking OpenCode changelog or GitHub issues for a hooks API; re-enable if found.

## 11. Harness documentation audit and global workflow support

- [x] 11.1 Codex: switched to Codex-specific TOML hooks only, quarantined legacy
  `~/.codex/hooks.json`, removed unsupported `async`, added `UserPromptSubmit`, disabled
  startup update checks, and added explicit compaction rules.
- [x] 11.2 Codex: added a managed OpenSpec workflow plugin and registered an `explore`
  agent role so Codex can use explicit planning/exploration without per-repo init.
- [x] 11.3 Shared skills/subagents: added global `openspec-workflow` guidance and a
  generated `explore` subagent definition.
- [x] 11.4 Copilot CLI: moved config to `~/.copilot/config.json`, moved MCP servers to
  `~/.copilot/mcp-config.json`, and changed local MCP entries to `type = "local"`.
- [x] 11.5 Cursor Agent: added `~/.cursor/mcp.json`.
- [x] 11.6 Antigravity: switched remote MCP entries from Claude-shaped `url` to
  agy-shaped `serverUrl`.
- [x] 11.7 OpenCode: removed stale AWS remote-MCP disablement now that current config
  accepts URL-based remote MCP entries.
- [x] 11.8 Amp: removed undocumented experimental plan-mode setting, disabled self
  updates, and corrected the global AGENTS comment.
- [x] 11.9 Crush: added `global_context_paths` so the managed global instructions file is
  actually loaded.

## 8. Session tree shortcut hints (capability: session-tree-switcher)

- [x] 8.1 Updated `open_session_tree` in `ui.lua` — picker title now shows
  `[^b blocked · ^g agents · ^d dormant · ^a all]`; filtered views show the active
  filter name in brackets instead.
- [x] 8.2 Verified: build green. Applied: `nh darwin switch`.
- [ ] 8.3 Confirm (human, live): open `SUPER+s`; hint line appears in title bar.
  `Ctrl+B/G/D/A` filter correctly; each filtered view shows which filter is active.

## 10. Session tree UX improvements (capability: session-tree-switcher)

- [x] 10.1 Badge color in `format-tab-title` updated to use `pane_badge_color(pid, cfg.colors)`
  instead of inline brights-slot arithmetic — consistent with the session tree.
- [x] 10.2 `ws.last_active` tracking: each workspace now records the max `since` across its panes.
- [x] 10.3 Recency sort: live workspaces in the "all" and new "sessions" views are sorted
  by `last_active` descending (most recently active session first).
- [x] 10.4 `sessions` filter (`Ctrl+S`): new workspace-only view — one row per live session
  with name + agent status icon + age since last activity. Quick overview without tab/pane noise.
- [x] 10.5 `Ctrl+]` / `Ctrl+[` inside the picker: cycle workspaces without entering the tree.
  Closes the picker and switches `SwitchWorkspaceRelative(±1)` after a 50 ms delay.
- [x] 10.6 `SUPER+]` / `SUPER+[` standalone bindings: workspace cycle without opening the picker,
  mirroring nvim buffer-cycle convention. Both are locked-mode passthrough aware.
- [x] 10.7 Updated title hint and `fuzzy_description` to include `^s sessions` and `^]/[ cycle`.
- [x] 10.8 Build green. Applied: `nh darwin switch`.
- [x] 10.9 Made the fuzzy-search suffix visible and muted (`[session/tab  tokens]`)
  instead of background-colored, so selected rows do not render unreadable
  black/right-edge text.
- [x] 10.10 Added a Codex sigil alias for `.codex-wrapped` / `codex-wrapped` so
  Codex tabs resolve through the same clean process-label path as Claude.
- [ ] 10.11 Confirm (human, live): open `SUPER+s`; verify recency order, `Ctrl+S` sessions view,
  `Ctrl+]/[` workspace cycle, `SUPER+]/[` direct cycle, and improved color legibility.

## 9. Commit and push

- [x] 9.1 `nix fmt` clean (build passed with no fmt errors).
- [x] 9.2 Committed: `feat(agents): session UI and notification refinements`
- [x] 9.3 Pushed to `main` (commit `4362de51b`).
