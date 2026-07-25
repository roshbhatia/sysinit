# adversarial-review-gating Specification

## Purpose
Gate the LLM adversarial-review critic loop behind an owner decision (default on, waiver recorded), while keeping the deterministic `specutil check` lint mandatory.
## Requirements
### Requirement: The critic loop is owner-gated at slice entry
The `adversarial-review` skill MUST elicit an owner approve/deny before it spawns critics, defaulting to run. On approve it runs the critic loop as today. On deny it MUST record the decision in the slice (`adversarial review: waived by owner`) rather than silently skipping. The gate applies only to the LLM critic loop, not to the deterministic `specutil check` lint.

#### Scenario: Owner approves the review
- **POLARITY** positive
- **WHEN** a slice reaches its adversarial-review step and the owner approves the elicitation
- **THEN** the skill spawns the critics and runs the refutation loop as before

#### Scenario: Owner denies and the waiver is recorded
- **POLARITY** negative
- **WHEN** the owner denies the review elicitation for a slice
- **THEN** the critic loop is skipped
- **AND** the slice's review checkbox is marked with `waived by owner` rather than left unmarked or silently checked

### Requirement: The deterministic lint stays mandatory
The deterministic rubric-lint MUST run on every change regardless of the critic-loop gate, because it is cheap and pure. A waived critic loop MUST NOT waive the lint; its violations still block the slice. The lint is `specutil check`, which reads the same declared markers and enforces the same rules from specutil's own parse.

#### Scenario: The lint runs even when the loop is waived
- **POLARITY** positive
- **WHEN** the critic loop is waived by the owner
- **THEN** `specutil check <change-dir>` still runs and must pass before the slice is done

#### Scenario: A lint violation blocks a waived slice
- **POLARITY** negative
- **WHEN** the critic loop is waived AND `specutil check` reports a rubric violation
- **THEN** the slice is not done, because the deterministic lint is not gated

