# cli-foundation Specification

## Purpose
TBD - created by archiving change specutil-core. Update Purpose after archive.
## Requirements
### Requirement: Deterministic binary with no network I/O
The `specutil` binary SHALL perform no network I/O in any code path. All remote interaction MUST be delegated to an external agent via emitted artifacts (plans) and shipped skills. Any durable local-state mutation MUST be exposed as an explicit CLI verb.

#### Scenario: Binary runs offline
- **WHEN** any `specutil` subcommand is invoked with no network available
- **THEN** the command completes (or fails) using only local filesystem and stdin/stdout, never attempting an outbound connection

#### Scenario: Attempted network dependency is rejected
- **WHEN** the build or a code-review introduces an import that performs network I/O from a binary code path
- **THEN** the determinism check (lint/test) fails and the change is rejected

### Requirement: Cobra root command and verb registry
The CLI SHALL expose its functionality through a cobra root command with the subcommands `render`, `plan`, `diff`, `lock`, `graph`, and `web`. There SHALL be no `sync` verb in the binary.

#### Scenario: Help lists the verb surface
- **WHEN** the user runs `specutil --help`
- **THEN** the output lists exactly the supported verbs and does not list a `sync` command

#### Scenario: Unknown verb is rejected
- **WHEN** the user runs `specutil bogus`
- **THEN** the CLI exits non-zero with an error naming the unknown command and does not perform any action

### Requirement: Embedded, overridable assets
Templates and static web assets SHALL be embedded in the binary via `embed.FS` so the tool runs with no external asset files, and SHALL be overridable from a user-specified directory.

#### Scenario: Runs with embedded defaults
- **WHEN** the user runs a verb that needs a template and provides no override
- **THEN** the embedded default asset is used

#### Scenario: User override takes precedence
- **WHEN** the user supplies an override directory containing a matching asset
- **THEN** the override asset is used instead of the embedded default

#### Scenario: Missing override asset falls back loudly
- **WHEN** an override directory is supplied but lacks a requested asset
- **THEN** the tool falls back to the embedded default and emits a warning naming the missing asset

### Requirement: Reproducible toolchain
The repository SHALL provide a Nix flake / dev shell pinning the Go toolchain and tools so the project builds and tests reproducibly.

#### Scenario: Dev shell builds the binary
- **WHEN** a contributor enters the provided dev shell and builds
- **THEN** the binary compiles and `go test ./...` runs without requiring globally-installed tools

