## Why

Several gaps remain after the session-switcher redesign, harness notification overhaul, and
agent-state bus work done in `build-session-tree-switcher` and
`build-agent-state-bus-and-surfaces`. These are small, surgical improvements that were
identified during live use but deferred from earlier changes:

- **Dead tabline config.** `tab_active` / `tab_inactive` in `tabline.setup` are never
  reached because our `format-tab-title` Lua handler always fires first and returns before
  tabline's own handler can. The config is noise and a future trap.
- **Tab titles don't reflect agent state.** The tab bar shows directory and process but
  never whether the pane's agent is waiting, working, or done. The `tab_agent_indicator`
  component in the dead tabline config was the intended vehicle; it needs to move into our
  own `format-tab-title` handler where it will actually run.
- **Notification click leaves the toast on screen.** `agent-focus.sh` navigates correctly
  to the right pane on click, but the triggering notification stays visible until its
  timeout elapses. One `terminal-notifier -remove` call at the top of the script closes it
  immediately.
- **Amp, Gemini (agy), OpenCode have no lifecycle hooks.** These harnesses emit no
  `agent_state` user-vars, write no state files, and send no notifications. The `agent-deck`
  scraper provides rough fallback detection, but there is no reason/age metadata and no
  desktop notification when Amp or OpenCode finishes a long task. All three have lifecycle
  hook surfaces that are not yet wired.
- **Codex done notifications fire unconditionally.** Codex has no `UserPromptSubmit`
  equivalent, so the `.start` timestamp file is never written and every Stop fires a
  notification regardless of how long the session ran. Writing the `.start` file from
  Codex's `PermissionRequest` hook (a reliable signal that the user is in an active
  session) gates short Codex responses the same way Claude's are.
- **Session tree keyboard shortcuts are not discoverable.** The picker has `^d` / `^b` /
  `^a` filter bindings but no visible hint. A static footer line in the picker title makes
  these discoverable without any documentation.

### Non-goals

- **No new harness instrumentation beyond the four identified.** Cursor, Aider, and other
  harnesses are out of scope for this pass.
- **No overhaul of the notification sound/timing model.** The Blow/Pop/Ping sounds and
  elapsed-time gate introduced in the preceding pass are not revisited here.
- **No change to the session-tree data model.** The workspace→tab→pane walk, dormant
  session merging, and attention-zone logic from `build-session-tree-switcher` are
  unchanged.
- **No new MCP servers or permissions changes.** The allowlist and MCP tier are untouched.

## What Changes

### Dead tabline config removal

Remove the `tab_active` and `tab_inactive` sections from `tabline.setup` in
`modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua`. These sections declare a
`tab_agent_indicator` function component and stock index/cwd/process fields, but tabline's
`format-tab-title` handler never fires because our own handler (registered before
tabline's) always returns a value. Removing them eliminates dead code and the misleading
implication that tabline controls tab rendering.

### Agent state prefix in format-tab-title

Inject the agent-state icon directly into our `format-tab-title` handler by reading
`pane.user_vars.agent_state` from the `PaneInformation` struct (which already carries
user vars as a plain table — no method call needed). When the var is present and the
status is non-idle, prepend the state icon (`◔` waiting / `⟳` working / `✔` done) to the
ribbon before the process icon. Idle state is intentionally omitted to avoid visual noise
on unattended panes; only actionable or in-progress states surface in the tab bar.

### Notification dismiss on navigation

Add `terminal-notifier -remove "$group"` at the start of `agent-focus.sh` before the
pane-activation steps. The `$group` is reconstructed from the same `agent-notify:$agent:$context`
pattern as the originating notification using the pane's state-file metadata.
When the state file is absent or `terminal-notifier` is not available the script
falls through to the existing activation logic unchanged.

### Amp lifecycle hooks

Wire `agent-state` and `agent-notify` into Amp's lifecycle events in
`modules/home/programs/llm/config/amp.nix`. Amp exposes hook events via
`amp.hooks` in `settings.json`:
- `AgentEnd` → `agent-notify amp done` + `agent-state amp done "your move"`
- `ToolCallStart` → `agent-state amp working tool` (async)
- `UserMessageSent` → `agent-state amp working submit` (writes `.start` file, async)

### agy (Antigravity) lifecycle hooks

Wire `agent-state` and `agent-notify` into agy's hook surface in `gemini.nix` (which
targets `pkgs.antigravity-cli`). agy exposes `hooks` in its config JSON: `onStop`,
`onToolStart`, `onUserMessage`. Mirror the Claude pattern: submit → working/submit,
tool start → working/tool, stop → done + notify.

### OpenCode lifecycle hooks

Wire `agent-state` and `agent-notify` into OpenCode's `$run` lifecycle hooks in
`opencode.nix`. OpenCode's `opencode.json` supports `hooks.session.start`,
`hooks.session.end`, and `hooks.tool.before`. Wire: session start → working/submit,
tool before → working/tool (async), session end → done/notify.

### Codex session-start tracking

In `codex.nix`, add a second hook command to the existing `PermissionRequest` entry:
`agent-state codex working submit`. Since Codex's first user interaction triggers a
`PermissionRequest` (the directory-trust prompt, or the first real tool approval), this
writes the `.start` file and gates the subsequent `Stop` done-notification on elapsed
time — the same 60-second threshold Claude uses.

### Session tree shortcut hints

Add a subtitle/title suffix to the `InputSelector` in `open_session_tree` that
surfaces the active filter bindings. The picker title becomes e.g.
`"  session tree  [^d dormant · ^b blocked · ^a agents]"` so the available
filter keys are visible as soon as the picker opens without any external documentation.

## Capabilities

### New Capabilities

- `amp-lifecycle-hooks`: Amp writes per-pane agent-state and fires desktop notifications
  on turn completion, matching the fidelity of the Claude harness.
- `agy-lifecycle-hooks`: agy (Antigravity CLI) writes per-pane agent-state and fires
  desktop notifications on turn completion.
- `opencode-lifecycle-hooks`: OpenCode writes per-pane agent-state and fires desktop
  notifications on turn completion.

### Modified Capabilities

- `session-tree-switcher`: tab titles now carry a live agent-state icon prefix (waiting /
  working / done) injected by the `format-tab-title` handler; shortcut hints appear in the
  picker title bar.
- `agent-notification-system`: notification click now dismisses the triggering toast
  immediately; Codex done-notifications are gated on the 60-second elapsed-time threshold
  via a `.start` file written at `PermissionRequest`.
