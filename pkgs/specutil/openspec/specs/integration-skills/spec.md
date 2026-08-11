# integration-skills Specification

## Purpose
TBD - created by archiving change specutil-core. Update Purpose after archive.
## Requirements
### Requirement: In-repo sync skills compose deterministic verbs
The repository SHALL ship `skills/sync-to-linear/SKILL.md` and `skills/sync-to-notion/SKILL.md` that instruct an agent to produce a plan with `specutil plan`, present operations for review, perform remote writes via the agent's MCP tools, and record results via `specutil lock set`. The skills SHALL NOT instruct the binary to make network calls.

#### Scenario: Skill drives the plan/apply flow
- **WHEN** the agent follows `sync-to-linear` for a change
- **THEN** it runs `specutil plan --target linear`, applies operations via the Linear MCP, and writes back identities via `specutil lock set`

#### Scenario: Write-back goes through the lock verb
- **WHEN** the agent creates a remote item
- **THEN** the resulting external ID is recorded by invoking `specutil lock set`, not by editing the lockfile or source artifacts directly

### Requirement: Confirmation by default with an auto escape hatch
The sync skills SHALL require per-operation (or batched) confirmation by default, and SHALL support a `--auto` / "just go do it" mode that proceeds without prompting.

#### Scenario: Default confirms before writing
- **WHEN** the agent follows a sync skill without the auto mode
- **THEN** it presents the planned operations and waits for confirmation before any remote write

#### Scenario: Auto mode skips prompts
- **WHEN** the user invokes the skill in auto mode
- **THEN** the agent applies the planned operations without per-operation prompts

#### Scenario: Confirmation declined performs no writes
- **WHEN** the operator declines at the confirmation step
- **THEN** no remote writes occur and no lock entries are changed

