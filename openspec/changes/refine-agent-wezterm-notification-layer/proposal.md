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
- **Harness hook assumptions drifted.** Amp, Antigravity, and OpenCode do not currently
  document lifecycle hook surfaces comparable to Claude/Codex, so previous hook plans
  would have created ignored or warning-producing config. Codex does document
  `UserPromptSubmit`, but its hook surface differs from Claude and does not support
  `async` entries in 0.142.x.
- **Harness MCP/config shapes drifted.** Copilot CLI, Cursor Agent, Antigravity, OpenCode,
  Amp, and Crush each expect different config paths or MCP field names. A Claude-shaped
  formatter was leaking into harnesses that need their own representation.
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

### Harness hook audit

Keep Claude and Codex hooks separate. Claude retains its documented JSON settings shape,
including `async` where the hook is best-effort. Codex uses TOML inline hooks only,
quarantines the legacy `~/.codex/hooks.json` layer, removes unsupported `async`, and uses
`UserPromptSubmit` for turn-start state instead of misusing `PermissionRequest`.

Amp, Antigravity, and OpenCode stay unwired until their current documentation or binaries
expose stable lifecycle hooks. The config comments and tasks should say "blocked/no
documented hook surface" instead of encoding guessed key names.

### Harness config/MCP audit

Make formatter output explicit per harness:
- Copilot CLI: `~/.copilot/config.json` plus `~/.copilot/mcp-config.json`; local MCP
  entries use `type = "local"`.
- Cursor Agent: `~/.cursor/mcp.json`.
- Antigravity: remote MCP entries use `serverUrl`.
- OpenCode: remote MCP is URL-capable; do not disable AWS based on stale SSE-only notes.
- Amp: remove undocumented experimental plan mode and disable self-updates in settings.
- Crush: point `global_context_paths` at the Nix-managed global instructions file.

### Session tree shortcut hints

Add a subtitle/title suffix to the `InputSelector` in `open_session_tree` that
surfaces the active filter bindings. The picker title becomes e.g.
`"  session tree  [^d dormant · ^b blocked · ^a agents]"` so the available
filter keys are visible as soon as the picker opens without any external documentation.

## Capabilities

### New Capabilities

- `harness-config-audit`: per-harness config paths and MCP field names are generated
  from documented shapes instead of sharing Claude-shaped assumptions.
- `global-openspec-workflow`: OpenSpec workflow guidance is installed globally through
  managed skills and a Codex plugin, without relying on per-project `openspec init`.

### Modified Capabilities

- `session-tree-switcher`: tab titles now carry a live agent-state icon prefix (waiting /
  working / done) injected by the `format-tab-title` handler; shortcut hints appear in the
  picker title bar.
- `agent-notification-system`: notification click now dismisses the triggering toast
  immediately; Codex hook state transitions use Codex's documented event names and one
  hook representation.
