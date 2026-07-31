## MODIFIED Requirements

### Requirement: Wire emission into each harness's lifecycle hooks

The emitter SHALL be invoked from every configured harness that exposes a
lifecycle surface, alongside the notifier, without altering notification or
click-to-focus behavior.

Claude SHALL wire `UserPromptSubmit` (working), `PreToolUse` (working with the
tool reason), `Notification` (the notifier only, because the agent is still
working), `Stop` (done), and `SessionEnd` (exit).

Codex SHALL wire `UserPromptSubmit` (working) and `Stop` (done). Codex exposes
no notification or session-end event, so its entry is reclaimed by the
collection step rather than by an exit hook.

Pi SHALL wire its extension events: `session_start` (working), `tool_call`
(working with the tool reason), `agent_settled` (done), and `session_shutdown`
(exit).

Pi SHALL NOT use `agent_end` for the done transition. Pi's bundled extension
documentation states that `agent_end` fires while pi may still auto-retry,
auto-compact, or run a queued follow-up, and directs a status integration to
`agent_settled` instead. Using `agent_end` would raise a done signal mid-run,
which is the duplicate-notification defect this work exists to remove.

OpenCode SHALL wire its plugin events for session idle (done) and session
error (waiting), conditional on those events being reachable from a
repository-authored plugin. The OpenCode plugin event list is undocumented.
String literals for `session.idle` and `session.error` exist in the installed
binary's internal event bus, which is suggestive but is not confirmation that a
plugin can subscribe to them. When the spike finds no reachable event, OpenCode
stays in the deferred set and this clause does not apply. An unconditional
SHALL here would archive a false requirement.

A harness that exposes no lifecycle surface SHALL contribute no state file.
It MUST NOT contribute a stale or synthesized entry, because the statusline
already falls back to agent-deck scraping for such a pane.

#### Scenario: Claude hooks invoke the emitter on every wired transition

- **POLARITY** positive
- **WHEN** the Claude hook configuration is rendered
- **THEN** each of `UserPromptSubmit`, `PreToolUse`, `Stop`, and `SessionEnd`
  includes a command invoking the emitter
- **AND** the notifier commands on `Notification` and `Stop` remain present

#### Scenario: Pi and OpenCode reach the bus through their own surfaces

- **POLARITY** positive
- **WHEN** the pi extension and the OpenCode plugin are loaded
- **THEN** each invokes the emitter on its harness's turn-start and turn-end
  events
- **AND** the written state file is indistinguishable in shape from Claude's

#### Scenario: Codex wires only the events it exposes

- **POLARITY** negative
- **WHEN** the Codex hook configuration is rendered
- **THEN** it contains no `Notification` or `SessionEnd` emitter entry
- **AND** the absence is recorded in `codex.nix` with the reason

#### Scenario: A hookless harness contributes nothing

- **POLARITY** negative
- **WHEN** a configured harness exposes no lifecycle surface
- **THEN** no state file is written for its panes
- **AND** the statusline falls back to the scraped status for those panes

#### Scenario: Emitter failure does not break the harness turn

- **POLARITY** negative
- **WHEN** the emitter exits non-zero or hangs
- **THEN** the agent harness's turn is unaffected
- **AND** no emission still leaves the notifier behavior intact
