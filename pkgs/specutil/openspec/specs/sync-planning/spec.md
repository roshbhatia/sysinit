# sync-planning Specification

## Purpose
TBD - created by archiving change specutil-core. Update Purpose after archive.
## Requirements
### Requirement: Plan verb emits deterministic operations
The `plan` verb SHALL project a change's IR against a target system (`--target linear|notion`) and the change's lockfile into a deterministic `plan.json` describing create/update/orphan operations. `plan` SHALL make no network calls.

#### Scenario: New items plan as creates
- **WHEN** `plan --target linear` runs and no lock entry exists for a task
- **THEN** the plan contains a create operation for that task

#### Scenario: Changed items plan as updates
- **WHEN** a task's content hash differs from its lock entry
- **THEN** the plan contains an update operation referencing the existing external ID

#### Scenario: Lock entries without source plan as orphans
- **WHEN** a lock entry has no corresponding current task
- **THEN** the plan marks it orphaned for the operator to resolve

#### Scenario: Plan performs no network I/O
- **WHEN** `plan` is run offline
- **THEN** it completes using only the local IR and lockfile

### Requirement: Per-change lockfile managed via lock verb
External identity SHALL be stored in a per-change `openspec/changes/<name>/specutil.lock.yaml` mapping stable content hashes → external IDs. The mapping SHALL be read and mutated only through `lock get` and `lock set`; specutil SHALL NOT write external IDs into OpenSpec source artifacts.

#### Scenario: Set then get round-trips
- **WHEN** the agent runs `lock set <hash> <external-id>` and later `lock get <hash>`
- **THEN** the stored external ID is returned

#### Scenario: Source artifacts stay clean
- **WHEN** identities are recorded
- **THEN** no external IDs are written into `tasks.md` or other OpenSpec source files

#### Scenario: Get for unknown hash
- **WHEN** `lock get` is called for a hash with no entry
- **THEN** the command reports no mapping and exits with a distinguishable status rather than fabricating an ID

### Requirement: Stable content-hash identity
Hashing SHALL derive a stable identity for a task that survives renumbering and minor text edits, using a normalized position-independent key. `diff` SHALL support fuzzy re-matching to limit false orphans on edits.

#### Scenario: Renumbering preserves identity
- **WHEN** a task is renumbered (e.g., 1.2 → 1.3) but its normalized text is unchanged
- **THEN** its hash and thus its external-ID mapping are preserved

#### Scenario: Distinct tasks do not collide
- **WHEN** two different tasks exist in the same change
- **THEN** their hashes differ

### Requirement: Diff verb reports drift
The `diff` verb SHALL compare the current IR against the lockfile and report which items are new, changed, or orphaned, with no network I/O.

#### Scenario: Diff reports drift categories
- **WHEN** a change has one new task, one edited task, and one removed task that exists in the lock
- **THEN** `diff` reports one new, one changed, and one orphaned item respectively

