## ADDED Requirements

### Requirement: A forked schema captures recurring authoring rules
A project-local OpenSpec schema MUST exist at `openspec/schemas/rosh-spec-driven/`, forked from the upstream `spec-driven` schema via `openspec schema fork spec-driven rosh-spec-driven`. The fork SHALL be the place where the user's recurring "manual rules" for proposal/design/tasks/specs authoring are encoded.

#### Scenario: Schema is discoverable
- **WHEN** `openspec schema which rosh-spec-driven` is run from the repo root
- **THEN** it reports the path `openspec/schemas/rosh-spec-driven/`

#### Scenario: Schema validates
- **WHEN** `openspec schema validate rosh-spec-driven` is run
- **THEN** it exits zero with no warnings

### Requirement: Schema additions beyond upstream are documented
Every change made to the forked schema relative to upstream `spec-driven` MUST be documented in `openspec/schemas/rosh-spec-driven/CHANGES.md` with one bullet per rule, citing the upstream file or section being overridden.

#### Scenario: Undocumented divergence caught
- **WHEN** a template file in the fork differs from upstream but `CHANGES.md` does not mention it
- **THEN** `hack/sync-openspec-skills.sh` (or the equivalent diff script) prints a warning naming the undocumented file

### Requirement: Projects reference the fork through config.yaml
Each project's `openspec/config.yaml` that participates in this workflow MUST set `schema: rosh-spec-driven` (resolved either by local path or by Git URL once published). The sysinit repo's own `openspec/config.yaml` SHALL reference the local fork by relative path.

#### Scenario: Sysinit uses the fork
- **WHEN** `openspec config get schema` is run in the sysinit repo
- **THEN** the resolved value points at `openspec/schemas/rosh-spec-driven/`

#### Scenario: Foreign project picks up the fork
- **WHEN** a user copies the documented `openspec/config.yaml` snippet into a new project and runs `openspec status --json`
- **THEN** the response reports `schemaName: rosh-spec-driven`

### Requirement: Upstream drift is detected, not auto-merged
A maintenance script MUST exist that diffs the forked schema against the upstream `spec-driven` schema shipped with the currently-installed openspec version, and reports any upstream files whose hashes have changed since the last sync. The script SHALL NOT modify the fork; it only reports.

#### Scenario: Upstream change reported
- **WHEN** openspec is bumped to a version where upstream `spec-driven/templates/proposal.md.hbs` has changed and `hack/sync-openspec-schema.sh` is run
- **THEN** the script prints a diff for that file and exits non-zero so CI can flag the drift

### Requirement: Manual rules encoded as schema-level constraints
At minimum, the fork MUST encode the following rules into the appropriate templates or instructions (placement determined when authoring the schema, but each MUST be enforced by the schema rather than relying on per-session reminders):

- Proposals MUST include a "Non-goals" subsection under "What Changes" when scope ambiguity is plausible.
- `tasks.md` MUST chunk work into named phases when the change touches more than one capability.
- Every `specs/<cap>/spec.md` requirement MUST have at least one negative scenario (a "WHEN <unexpected condition> THEN <error/rejection>" pair).
- `design.md` MUST contain a "Decisions" section that records, per decision, the alternatives considered and why they were rejected.

#### Scenario: Negative scenario rule enforced at validate time
- **WHEN** a spec.md adds a requirement with only positive scenarios and `openspec validate` is run
- **THEN** the command warns or errors with a message that references the negative-scenario rule

#### Scenario: Non-goals reminder appears at propose time
- **WHEN** an agent invokes `openspec instructions proposal --change <name>`
- **THEN** the returned `instruction` text mentions the Non-goals requirement when the change touches more than one capability
