# pi-openspec-bridge Specification

## Purpose
TBD - created by archiving change refresh-pi-stack. Update Purpose after archive.
## Requirements
### Requirement: openspec-status extension exists and is vendored
A custom TypeScript extension MUST exist at `modules/home/programs/llm/config/extensions/openspec-status.ts` (the canonical Nix source) and be installed to `~/.pi/agent/extensions/openspec-status.ts` via `home.file`. It SHALL be loaded by pi via the existing `extensionsDir`-style mechanism the file is alongside the upstream-fetched extension `.ts` files.

#### Scenario: Extension materializes on activation
- **WHEN** `nh darwin switch .` completes
- **THEN** `~/.pi/agent/extensions/openspec-status.ts` exists with content byte-identical to the source under `modules/`

#### Scenario: Hand-edit reverted on next activation
- **WHEN** a user edits `~/.pi/agent/extensions/openspec-status.ts` directly and re-runs activation
- **THEN** the file is reset to match the Nix source

### Requirement: Status display is read-only
The extension SHALL be strictly read-only in this first version. It MUST NOT call `openspec new`, `openspec archive`, or any mutating openspec subcommand. It MUST NOT register a tool that pi could be asked to invoke. It MUST NOT intercept tool calls to gate them. Status display via a status-line item is the entire surface.

#### Scenario: Extension only reads
- **WHEN** the extension's source is inspected
- **THEN** every shell-out invokes `openspec list --json` or `openspec status --change <name> --json` with no mutating subcommand and no `-f`, `--force`, `new`, `archive`, `config set`, `config unset`, or `schema fork` flags

#### Scenario: Failure modes
- **WHEN** the `openspec` CLI is not on PATH or returns non-zero
- **THEN** the status-line item renders the literal string `openspec: n/a` and the extension does not throw or crash pi
- **AND** the failure is logged once per session at debug level

### Requirement: Active-change discovery is deterministic
The extension MUST identify "the active change" via the following rule, in order: (1) if exactly one entry exists in `openspec list --json` `.changes`, that is the active change; (2) if more than one, the most recently modified change directory (mtime of `<change-dir>/.openspec.yaml`) is the active change; (3) if zero, render `openspec: idle`. This rule SHALL match what `/opsx:apply` does when auto-inferring.

#### Scenario: Single active change
- **WHEN** `openspec list --json` returns one entry named `add-feature-x`
- **THEN** the status-line item renders `openspec: add-feature-x · N/M tasks`

#### Scenario: Multiple active changes
- **WHEN** two changes are active, with `change-b` modified more recently than `change-a`
- **THEN** the status-line picks `change-b` and renders its name + progress

#### Scenario: No active change
- **WHEN** `openspec list --json` returns an empty list
- **THEN** the status-line renders `openspec: idle`

#### Scenario: openspec command times out
- **WHEN** invoking `openspec list --json` exceeds 2 seconds
- **THEN** the extension aborts the shell-out, renders the last cached value if any (else `openspec: n/a`), and does not block pi's rendering loop

### Requirement: Refresh cadence is rate-limited
The extension SHALL refresh its status by re-invoking `openspec list --json` at most every 5 seconds. It MUST cache the most recent result across renders and only re-shell when the cache TTL expires or when a relevant event-bus event fires (e.g., a tool call writes to a path under `openspec/changes/`).

#### Scenario: Quick consecutive renders
- **WHEN** pi's UI re-renders 10 times in 1 second
- **THEN** the extension invokes `openspec list --json` at most once

#### Scenario: Cache invalidated by file write
- **WHEN** a tool call writes to `openspec/changes/**` and the cache TTL has not yet expired
- **THEN** the extension invalidates its cache and re-invokes `openspec list --json` on the next render

