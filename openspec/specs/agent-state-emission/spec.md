# agent-state-emission Specification

## Purpose
TBD - created by archiving change surface-agent-session-state. Update Purpose after archive.
## Requirements
### Requirement: Emit per-pane lifecycle state to WezTerm

An agent-agnostic emitter script SHALL publish the calling agent's current
lifecycle state to its WezTerm pane on each lifecycle transition, encoded as an
OSC 1337 `SetUserVar` named `agent_state`. The emitter SHALL reuse the same
session·repo·pane identity resolution used by `agent-notify.sh` and SHALL be
best-effort: any failure (no tty, missing pane, encode error) MUST result in a
silent no-op with exit code 0, never an error surfaced to the agent harness.

The `agent_state` value SHALL be the base64 encoding of a single delimited line
`<status>|<reason>|<since_epoch>|<agent>`, where `status` is one of `working`,
`waiting`, `done`, or `idle`; `reason` is a single-line human string; `since_epoch`
is the Unix timestamp of the transition; and `agent` is the harness name.

#### Scenario: PreToolUse stamps working with the tool reason

- **WHEN** the emitter is invoked for a Claude `PreToolUse` event for the `Bash`
  tool running `nix flake check`
- **THEN** it writes an OSC 1337 `SetUserVar=agent_state=<base64>` to the pane's
  controlling tty
- **AND** the decoded value's `status` field is `working`
- **AND** the `reason` field names the tool and its squashed input (e.g.
  `Bash: nix flake check`)

#### Scenario: Notification stamps waiting with the harness reason

- **WHEN** the emitter is invoked for a Claude `Notification` event whose message
  is `Claude needs your permission to use Bash`
- **THEN** the decoded `status` is `waiting`
- **AND** the `reason` carries the harness message text

#### Scenario: Stop stamps done

- **WHEN** the emitter is invoked for a `Stop` event
- **THEN** the decoded `status` is `done`

#### Scenario: Reason is squashed to a single safe line

- **WHEN** the reason source contains newlines or the `|` delimiter character
- **THEN** the emitted `reason` collapses whitespace to single spaces, replaces
  the delimiter, and is truncated to a bounded length
- **AND** the decoded line still splits into exactly four fields

#### Scenario: No controlling tty is a silent no-op

- **WHEN** the emitter runs in a process with no controlling tty or with
  `WEZTERM_PANE` unset
- **THEN** it writes nothing and exits 0
- **AND** no error is printed to stdout or stderr

### Requirement: Wire emission into each harness's lifecycle hooks

The emitter SHALL be invoked from the existing Claude and Codex hook
configurations alongside the unchanged notifier, without altering the
notification or click-to-focus behavior. Claude SHALL wire `UserPromptSubmit`,
`PreToolUse`, `PostToolUse`, `Notification`, and `Stop`. Codex SHALL wire
`PermissionRequest` (waiting) and `Stop` (done); Codex working/idle state is
out of scope for emission and is covered by the rollup's fallback.

#### Scenario: Claude hooks invoke the emitter on every wired transition

- **WHEN** the Claude hook configuration is rendered
- **THEN** each of `UserPromptSubmit`, `PreToolUse`, `PostToolUse`,
  `Notification`, and `Stop` includes a command invoking the emitter
- **AND** the existing notifier commands on `Notification` and `Stop` remain
  present and unchanged

#### Scenario: Codex wires only the events it exposes

- **WHEN** the Codex hook configuration is rendered
- **THEN** `PermissionRequest` invokes the emitter with `waiting` and `Stop` with
  `done`
- **AND** no `PreToolUse`/`UserPromptSubmit` emitter entry is added for Codex
  (it exposes no such events)

#### Scenario: Emitter failure does not break the harness turn

- **WHEN** the emitter exits non-zero or hangs
- **THEN** the agent harness's turn is unaffected (the hook is async/best-effort)
- **AND** no emission still leaves the notifier behavior intact

### Requirement: Liveness is the reader's rule, stated once

A state file is evidence that a pane held a state, not that the pane still
exists. Every reader SHALL intersect the state files with the live pane set
before drawing a conclusion, and SHALL treat a file naming a pane id that no
longer exists as absent.

A reader that cannot determine the live pane set SHALL skip the agent-state
input entirely rather than treat every file as live. Assuming liveness turns one
crashed session into a permanent blocker on every surface that reads the bus.

This rule already governs the WezTerm statusline, which prunes against
`wezterm.mux.all_windows()`. It is stated here because the readiness report is a
second reader outside WezTerm's Lua, and a per-reader reimplementation is how
two surfaces come to disagree.

#### Scenario: A reader ignores a dead pane's file

- **POLARITY** positive
- **WHEN** a state file names a pane id absent from the live pane set
- **THEN** the reader treats it as absent

#### Scenario: A reader that cannot see the pane set skips the input

- **POLARITY** negative
- **WHEN** the live pane set cannot be determined
- **THEN** the reader skips the agent-state input and says so
- **AND** it does not report every state file as a live agent

