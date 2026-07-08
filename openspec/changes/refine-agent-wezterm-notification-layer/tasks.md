## 1. Dead tabline config removal (capability: session-tree-switcher)

- [ ] 1.1 Remove the `tab_active` and `tab_inactive` blocks from `tabline.setup` in
  `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua`. These sections
  (including the `tab_agent_indicator` function component and index/cwd/process
  fields) are unreachable — our `format-tab-title` handler always returns before
  tabline's handler fires.
- [ ] 1.2 Verify: `nix flake check` + `nh darwin build` green (luajit `loadfile` syntax
  check, closure unchanged or smaller). Confirm the tab bar still renders — removing
  dead tabline config has no visual effect.

## 2. Agent state prefix in tab title (capability: session-tree-switcher)

- [ ] 2.1 In the `format-tab-title` handler in `ui.lua`, read
  `pane.user_vars.agent_state` (plain table lookup, not a method). Decode the
  pipe-delimited `status|reason|since|agent` string via `pcall`. When status is
  `working`, `waiting`, or `done`, prepend the corresponding icon (`⟳` / `◔` / `✔`)
  to the tab ribbon before the process icon. Idle state: no prefix.
- [ ] 2.2 Verify: `nix flake check` + `nh darwin build` green.
- [ ] 2.3 Apply: `nh darwin switch`.
- [ ] 2.4 Confirm (human, live): start a task in Claude Code; the active tab shows `⟳`
  while working and `◔` when waiting for approval. Idle/unstarted panes show no
  prefix. `nix fmt` clean.

## 3. Notification dismiss on navigation (capability: agent-notification-system)

- [ ] 3.1 In `agent-focus.sh`, at the start of the script (before pane-activation
  steps), read the state file for the given pane id (`$state_dir/$1.json`). If it
  exists, parse `agent` and the `session`/`repo` fields to reconstruct the
  `agent-notify:$agent:$context` group string, then call
  `terminal-notifier -remove "$group"`. Guard with `command -v terminal-notifier` so
  the script still works on non-Mac or without the tool.
- [ ] 3.2 Verify: `nh darwin build` green. Confirm `agent-focus.sh` syntax (`bash -n`).
- [ ] 3.3 Apply: `nh darwin switch`.
- [ ] 3.4 Confirm (human, live): trigger a done notification (e.g. run a 60+ second
  Claude task), click it; confirm the toast disappears immediately on click rather than
  persisting to its timeout.

## 4. Codex session-start tracking (capability: agent-notification-system)

- [ ] 4.1 In `codex.nix`, add a third hook command to the existing
  `PermissionRequest` hooks list:
  `"${profileBin}/agent-state codex working submit"` (no `async` flag — matching the
  working/submit pair's urgency). This fires the `submit` branch of `agent-state.sh`
  which writes the `.start` timestamp file, gating the subsequent `Stop`
  done-notification on elapsed time.
- [ ] 4.2 Verify: `nix flake check` + `nh darwin build` green.
- [ ] 4.3 Apply: `nh darwin switch`.
- [ ] 4.4 Confirm (human, live): run a quick Codex interaction (< 60 seconds from
  first PermissionRequest to Stop); confirm no done notification fires. Run a longer
  task (> 60 s); confirm a done notification fires.

## 5. Amp lifecycle hooks (capability: amp-lifecycle-hooks)

- [ ] 5.1 Verify the available Amp hook event names against the installed Amp version
  (`amp --version` + changelog or config schema). Confirm `AgentEnd`, `ToolCallStart`,
  and `UserMessageSent` (or their current equivalents) exist.
- [ ] 5.2 In `amp.nix`, add an `"amp.hooks"` key to `ampConfig` with:
  - `UserMessageSent`: `["${profileBin}/agent-state amp working submit"]` (async)
  - `ToolCallStart`: `["${profileBin}/agent-state amp working tool"]` (async)
  - `AgentEnd`: `["${profileBin}/agent-notify amp done ${profileBin}/agent-focus",
                   "${profileBin}/agent-state amp done \"your move\""]` (async)
- [ ] 5.3 Verify: `nix flake check` + `nh darwin build` green. Confirm the resulting
  `~/.config/amp/settings.json` carries the hook keys after switch.
- [ ] 5.4 Apply: `nh darwin switch`.
- [ ] 5.5 Confirm (human, live): start a task in Amp; confirm the pane's agent state
  updates (working → done), the statusline shows the state, and a done notification
  fires when the turn ends.

## 6. agy (Antigravity) lifecycle hooks (capability: agy-lifecycle-hooks)

- [ ] 6.1 Resolve Open Question: inspect `pkgs.antigravity-cli` to determine the config
  file path (`~/.config/agy/config.json` or otherwise) and the hook key names
  (`onStop`, `onToolStart`, `onUserMessage` or equivalents).
- [ ] 6.2 In `gemini.nix` (or create it), add hook wiring:
  - `onUserMessage`: `agent-state gemini working submit` (async)
  - `onToolStart`: `agent-state gemini working tool` (async)
  - `onStop`: `agent-notify gemini done` + `agent-state gemini done "your move"` (async)
  Use the same `builtins.toJSON` pattern as `amp.nix`.
- [ ] 6.3 Verify: `nix flake check` + `nh darwin build` green.
- [ ] 6.4 Apply: `nh darwin switch`.
- [ ] 6.5 Confirm (human, live): run an agy task; confirm done notification fires and
  state bus updates.

## 7. OpenCode lifecycle hooks (capability: opencode-lifecycle-hooks)

- [ ] 7.1 In `opencode.nix`, add a `hooks` key to `opencodeConfig`:
  ```
  hooks = {
    session.start = ["${profileBin}/agent-state opencode working submit"];
    session.end   = ["${profileBin}/agent-notify opencode done ${profileBin}/agent-focus"
                     "${profileBin}/agent-state opencode done \"your move\""];
    tool.before   = ["${profileBin}/agent-state opencode working tool"];
  };
  ```
  (The `updateOpencodeConfig` jq merge is `.[0] * .[1]` — the Nix-declared `hooks`
  key replaces any existing runtime-written one wholesale on each activation.)
- [ ] 7.2 Verify: `nix flake check` + `nh darwin build` green. Confirm
  `~/.config/opencode/opencode.json` carries the hooks block after activation.
- [ ] 7.3 Apply: `nh darwin switch`.
- [ ] 7.4 Confirm (human, live): start an OpenCode session; confirm state bus updates
  and a done notification fires when the session ends.

## 8. Session tree shortcut hints (capability: session-tree-switcher)

- [ ] 8.1 In `open_session_tree` in `ui.lua`, update the `InputSelector` `title`
  argument to append the filter-key hint:
  `"  session tree  [^d dormant · ^b blocked · ^a agents]"`.
  Keep the existing `fuzzy = true`, `fuzzy_description`, and `alphabet` unchanged.
- [ ] 8.2 Verify: `nh darwin build` green.
- [ ] 8.3 Apply: `nh darwin switch`.
- [ ] 8.4 Confirm (human, live): open `SUPER+s`; the picker title bar shows the hint
  line. `Ctrl+D`, `Ctrl+B`, `Ctrl+A` still filter correctly.

## 9. Commit and push

- [ ] 9.1 Run `nix fmt` — confirm all edited Nix files are clean.
- [ ] 9.2 Stage the changed files and propose a conventional commit message for user
  approval before committing.
- [ ] 9.3 Push to `main` after user confirmation.
