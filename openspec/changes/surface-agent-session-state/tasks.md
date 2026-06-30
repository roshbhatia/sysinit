## 1. Emission (capability: agent-state-emission)

- [ ] 1.1 Add `modules/home/programs/llm/config/agent-state.sh`, modeled on
  `agent-notify.sh`: resolve session·repo·pane via `WEZTERM_PANE` →
  `wezterm cli list` with the seshy-cwd fallback; accept `<agent> <status>
  [reason]` args; squash+truncate the reason; base64-encode
  `<status>|<reason>|<since_epoch>|<agent>`; write the OSC 1337
  `SetUserVar=agent_state=<b64>` to `/dev/tty`. Best-effort throughout: no
  errexit/nounset/pipefail, always `exit 0`, silent no-op when there is no tty.
- [ ] 1.2 Export the emitter from `notify.nix` via `pkgs.writeShellApplication`,
  following the existing `script`/`focusScript` pattern; expose its path
  (e.g. `stateExe`).
- [ ] 1.3 Wire Claude hooks in `claude.nix`: add the emitter to
  `UserPromptSubmit` (working/"thinking"), `PreToolUse` (working/tool+input),
  `PostToolUse` (working/"thinking"), `Notification` (waiting/message), `Stop`
  (done/"your move"). Leave the existing notifier commands on `Notification`
  and `Stop` unchanged.
- [ ] 1.4 Wire Codex hooks in `codex.nix`: add the emitter to `PermissionRequest`
  (waiting) and `Stop` (done) alongside the existing notifier.
- [ ] 1.5 Verify: `nix flake check` green; `nh darwin build` green.

## 2. Rollup (capability: agent-session-rollup)

- [ ] 2.1 Add a shared helper (new function in `pkg/ui.lua` or a small `pkg/`
  sibling) `agent_session_states()` that walks live panes, reads each pane's
  `agent_state` user-var, falls back to `agent-deck` per pane, groups by
  workspace, and reduces worst-wins (`waiting > done > working > idle`) carrying
  reason + age (oldest `since` on ties). Tolerate missing/garbled values as
  "no state". No shell-out on this path.
- [ ] 2.2 Verify: `nix flake check` + `nh darwin build` green. No surface reads
  the helper yet — nothing user-visible changes.

## 3. Switcher (capability: agent-aware-switcher)

- [ ] 3.1 Enrich `wm.get_choices` (`ui.lua:~513`) labels from
  `agent_session_states()`: append state icon + reason + age; keep bare names
  for stateless sessions; keep the pinned `default` entry; sort by urgency
  (precedence then longest age, stateless last).
- [ ] 3.2 Verify: `nh darwin build` green.
- [ ] 3.3 **Human checkpoint — live spot-check.** Open `SUPER+s` with a real
  blocked agent and confirm the row shows state·reason·age and sort order. This
  is where OSC-to-tty under Claude's alt-screen TUI is confirmed to land; if it
  does not, fall back to the kill switch (remove emitter hook lines) before
  proceeding.

## 4. Statusline (capability: agent-aware-statusline)

- [ ] 4.1 Rewrite `agent_status()` (`ui.lua:~196`) to name the worst session
  (icon + name + age) from the shared rollup, rendering empty when no session
  has state. Confirm the named session matches the switcher's top entry.
- [ ] 4.2 Verify: `nh darwin build` green.

## 5. Apply & confirm (impactful actions)

- [ ] 5.1 Review `git diff`; confirm `nix flake check` and `nh darwin build`
  are green.
- [ ] 5.2 **Impactful action — apply.** `nh darwin switch` (mutates the live
  system).
- [ ] 5.3 **Confirm live.** Blocked agent → switcher row and statusline both
  name it with reason/age; a hookless agent still appears via `agent-deck`
  fallback.
- [ ] 5.4 **Impactful action — publish.** Commit the implementation (conventional
  commit, title-only) and `git push` to `main` (this repo commits straight to
  main).
- [ ] 5.5 Ping the user that it is applied.
