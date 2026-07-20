# cross-harness-destructive-command-guard Specification

## Purpose
TBD - created by archiving change refine-harness-configs-and-refresh-pi. Update Purpose after archive.
## Requirements
### Requirement: Destructive command patterns are defined once and shared

The destructive-command deny patterns (force-push including force-with-lease,
`--no-verify`, `--no-gpg-sign`, `git reset --hard`, `git clean -f`,
`git branch -D`) MUST be defined once in `lib/allowlist.nix` and consumed by
each guarded harness through a per-harness formatter, mirroring the existing
`tierA`/`tierB` pattern.

#### Scenario: Single source of deny patterns

- **WHEN** a maintainer adds a new destructive pattern
- **THEN** it is added once in `lib/allowlist.nix`
- **AND** every guarded harness picks it up through its formatter

### Requirement: Codex mechanically denies destructive commands

The Codex config MUST add a `hooks.PreToolUse` command hook that denies the
shared destructive-command patterns. The hook's field extraction MUST be
verified against Codex's actual `PreToolUse` payload shape before wiring.

#### Scenario: Codex blocks a force-push

- **WHEN** a Codex session attempts `git push --force`
- **THEN** the `PreToolUse` hook denies the command
- **AND** a non-destructive command such as `git status` is unaffected

### Requirement: Amp denies destructive commands via native permissions

The Amp config MUST add `amp.permissions` entries that reject the shared
destructive-command patterns, using Amp's native permission mechanism rather
than a plugin.

#### Scenario: Amp rejects reset --hard

- **WHEN** an Amp session attempts `git reset --hard`
- **THEN** the Amp permission entry rejects the command

### Requirement: opencode denies destructive commands via permission.bash

The opencode config MUST add `permission.bash` map entries set to `deny` for the
shared destructive-command patterns, while keeping the existing `"*" = "allow"`
default.

#### Scenario: opencode denies clean -f

- **WHEN** an opencode session attempts `git clean -f`
- **THEN** the `permission.bash` deny pattern blocks the command
- **AND** an allowed command still runs without a prompt

### Requirement: Goose denies destructive commands via shell.deny

The Goose config MUST populate `shell.deny` with regex forms of the shared
destructive-command patterns (currently `deny = []`).

#### Scenario: Goose denies branch -D

- **WHEN** a Goose session attempts `git branch -D somebranch`
- **THEN** the `shell.deny` regex blocks the command

