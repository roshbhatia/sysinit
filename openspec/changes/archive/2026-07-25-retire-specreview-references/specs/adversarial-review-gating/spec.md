## MODIFIED Requirements

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
