## ADDED Requirements

### Requirement: The per-pane state file carries a schema version

The per-pane state file at
`$XDG_STATE_HOME/agents/panes/<pane>.json` MUST carry an integer schema version
field. A reader MUST be able to detect a version it does not understand without
inspecting the other fields.

The file is read by the Claude statusline, WezTerm `ui.lua`, seshy, neph, and
Neovim. Its contract is currently a comment in `agent-state.sh` and nothing
else.

#### Scenario: A written file carries its version

- **POLARITY** positive
- **WHEN** `agent-state` writes a state file
- **THEN** the file carries the current schema version as an integer

#### Scenario: A reader rejects an unknown version

- **POLARITY** negative
- **WHEN** a reader encounters a state file whose version is higher than the
  one it understands
- **THEN** the reader ignores that pane rather than misreading its fields
- **AND** the reader does not crash

### Requirement: The state file shape is validated by a check

A `nix flake check` derivation MUST run `agent-state` and validate its output
against a declared JSON schema. The schema MUST be the artifact the readers are
written against, so a field rename fails the build rather than five consumers
at runtime.

The check MUST cover every reason source the emitter accepts: `submit`, `tool`,
`message`, and a literal string.

#### Scenario: Emitted state validates against the schema

- **POLARITY** positive
- **WHEN** the check runs `agent-state claude working tool` with a sample
  `PreToolUse` payload
- **THEN** the written file validates against the schema
- **AND** the `status` and `reason` fields carry the expected values

#### Scenario: A renamed field fails the check

- **POLARITY** negative
- **WHEN** a maintainer renames a field in the emitter without updating the
  schema
- **THEN** the check fails and names the field
- **AND** `nix flake check` exits non-zero

#### Scenario: A malformed reason cannot produce invalid JSON

- **POLARITY** negative
- **WHEN** the reason source contains quotes, backslashes, and newlines
- **THEN** the written file is still valid JSON
- **AND** it still validates against the schema

### Requirement: Stale entries are collected without a per-harness exit hook

Only Claude wires a `SessionEnd` hook that removes its entry. Every other
harness leaves its file behind. Collection MUST NOT depend on each harness
wiring an exit hook, and MUST NOT require every reader to reimplement liveness
pruning.

Collection MUST run in one place and MUST be safe to run concurrently with an
emitter writing a new file.

#### Scenario: A dead pane's entry is collected

- **POLARITY** positive
- **WHEN** a state file names a pane id that no longer exists
- **THEN** collection removes the file

#### Scenario: A live pane's entry survives collection

- **POLARITY** negative
- **WHEN** collection runs while a live pane is mid-write
- **THEN** the live pane's entry is not removed
- **AND** no reader observes a partial file

#### Scenario: Collection outside WezTerm removes nothing

- **POLARITY** negative
- **WHEN** collection runs where the live pane set cannot be determined
- **THEN** it removes nothing rather than removing everything
- **AND** it exits without error

### Requirement: The emitter contract stays best-effort

Adding a version, a schema, and collection MUST NOT change the emitter's
existing contract. It MUST remain agent-agnostic, MUST NOT block, and MUST exit
zero on every failure path.

#### Scenario: Emission still succeeds inside a pane

- **POLARITY** positive
- **WHEN** the emitter runs inside a WezTerm pane
- **THEN** it writes the user variable and the state file
- **AND** it exits zero

#### Scenario: A schema-validation dependency is not required at runtime

- **POLARITY** negative
- **WHEN** the emitter runs on a machine with no JSON schema validator on PATH
- **THEN** it still writes the state file and exits zero
- **AND** validation remains a build-time concern only
