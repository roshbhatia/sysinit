## ADDED Requirements

### Requirement: Publish per-pane agent state as a state file

The emitter SHALL, in addition to its OSC `SetUserVar` emission, write the
calling agent's current state to a per-pane JSON file at
`~/.local/state/agents/panes/<WEZTERM_PANE>.json`, where `<WEZTERM_PANE>` is the
integer pane id from the environment. The write SHALL be atomic (write to a
temporary sibling file, then rename over the target) so a concurrent reader
never observes a partially written file. The file transport SHALL be
best-effort and independent of the OSC emit: failure to write the file MUST NOT
prevent the OSC emit, and vice versa, and either failure MUST still exit 0.

#### Scenario: Emission writes both transports

- **WHEN** the emitter is invoked with `WEZTERM_PANE` set and a writable state
  directory
- **THEN** it writes the OSC `SetUserVar` to the pane tty
- **AND** it writes `~/.local/state/agents/panes/<pane>.json` containing the
  current state
- **AND** the JSON file is created via a temp-file-plus-rename so no partial
  file is observable

#### Scenario: Unwritable state directory degrades to OSC only

- **WHEN** the state directory cannot be created or written (permission error,
  full disk)
- **THEN** the emitter still performs the OSC emit
- **AND** it exits 0 without surfacing an error to the agent harness

#### Scenario: Missing pane id skips the file transport

- **WHEN** the emitter runs with `WEZTERM_PANE` unset
- **THEN** it writes no state file
- **AND** it exits 0 (matching the existing no-tty no-op)

### Requirement: State file carries the enriched cross-surface payload

The state-file JSON SHALL be the documented public contract consumed by
out-of-WezTerm surfaces (neovim, `sy`, neph) and SHALL contain at least the
fields: `pane` (integer), `session` (resolved seshy session / WezTerm
workspace), `repo` (basename of the git toplevel or empty), `branch` (current
git branch or empty), `dirty` (boolean), `worktree` (absolute worktree path or
empty), `agent` (harness name), `status` (one of `working`, `waiting`, `done`,
`idle`), `reason` (single-line string), and `since` (Unix epoch integer of the
transition). Every value SHALL be JSON-typed such that a strict JSON parser
reads the file without error.

#### Scenario: Blocked Claude pane writes a complete record

- **WHEN** a Claude agent in repo `sysinit` on branch `main` transitions to
  `waiting` with reason `needs approval`
- **THEN** the state file's `status` is `waiting`, `reason` is `needs approval`,
  `repo` is `sysinit`, `branch` is `main`, and `agent` is `claude`
- **AND** `since` is the Unix timestamp of the transition

#### Scenario: Non-git working directory yields empty git fields

- **WHEN** the agent's working directory is not inside a git repository
- **THEN** `repo`, `branch`, and `worktree` are empty strings and `dirty` is
  `false`
- **AND** the file is still valid JSON that parses without error

#### Scenario: Reason containing quotes and newlines stays valid JSON

- **WHEN** the reason source contains double quotes, backslashes, or newlines
- **THEN** the written `reason` is a single line with those characters escaped
  or stripped
- **AND** a strict JSON parser reads the file without error

### Requirement: Share identity resolution between emitter and notifier

The system SHALL define the session, repo, and pane identity resolution
(WezTerm workspace lookup with the seshy-cwd fallback, plus git repo and branch
derivation) exactly once and reuse it from both `agent-state.sh` and
`agent-notify.sh`. The two scripts MUST NOT disagree about which session or repo
a pane belongs to.

#### Scenario: Notifier and emitter resolve the same session

- **WHEN** both scripts run for the same pane in the same session
- **THEN** they resolve the same session name and repo for that pane

#### Scenario: Resolution failure is non-fatal for both

- **WHEN** the shared resolver cannot determine the session (no `wezterm cli`,
  no seshy match)
- **THEN** both scripts fall back to an empty/unknown session without error
- **AND** each still exits 0

### Requirement: Readers treat state files as advisory and prune by liveness

The state-file transport SHALL NOT guarantee deletion of a file when its pane
closes; consumers SHALL treat a state file as valid only when its `pane` id
corresponds to a currently live WezTerm pane, and SHALL ignore orphaned files.
The emitter MAY additionally remove a pane's state file on a terminal
transition (session-end / `Stop`) as best-effort cleanup, but correctness MUST
NOT depend on that cleanup running.

#### Scenario: Orphaned file from a closed pane is ignored

- **WHEN** a state file exists for a `pane` id that no longer appears in
  `wezterm cli list`
- **THEN** a conforming consumer ignores that file as stale

#### Scenario: Cleanup failure does not corrupt liveness filtering

- **WHEN** best-effort cleanup fails to delete a closed pane's file
- **THEN** consumers still correctly ignore it via the live-pane intersection
- **AND** no consumer treats the stale file as an active agent
