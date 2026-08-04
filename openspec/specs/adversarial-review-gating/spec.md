# adversarial-review-gating Specification

## Purpose

Keep deterministic review mandatory and treat model critique as optional evidence.

## Requirements

### Requirement: Model critique is optional evidence

The `adversarial-review` skill MUST run `specutil check` first. It MUST run the
model critic loop only when the user requests it or a concrete risk justifies
it. The critic result MUST NOT represent owner or peer approval.

#### Scenario: A concrete risk justifies critique

- **POLARITY** positive
- **WHEN** a phase has a named risk that benefits from an independent critic
- **THEN** the skill runs the bounded critic loop and records its terminal state

#### Scenario: No critique is justified

- **POLARITY** negative
- **WHEN** the user did not request critique and no concrete risk justifies it
- **THEN** the critic loop does not run
- **AND** the phase records `not run` without waiver language

### Requirement: The deterministic lint stays mandatory

The deterministic rubric lint MUST run on every change. A decision not to run
model critics MUST NOT skip or weaken the lint.

#### Scenario: The lint runs without model critique

- **POLARITY** positive
- **WHEN** model critique does not run
- **THEN** `specutil check <change-dir>` still runs and must pass

#### Scenario: A lint violation blocks the phase

- **POLARITY** negative
- **WHEN** model critique does not run and `specutil check` reports a violation
- **THEN** the phase remains incomplete

### Requirement: Review authorities stay distinct

Automation evidence, model critique, peer review, and owner approval MUST use
distinct records. The `decision` in `specutil.review.yaml` is an owner decision.
A model critic MUST write only its task result and open objections.

#### Scenario: A critic reaches CLEAN

- **POLARITY** positive
- **WHEN** no model objection survives a critic round
- **THEN** the task records `CLEAN` as model evidence without changing the owner decision

#### Scenario: A model attempts to approve

- **POLARITY** negative
- **WHEN** a model critic produces an approval verdict
- **THEN** the workflow rejects that verdict as an owner or peer decision
