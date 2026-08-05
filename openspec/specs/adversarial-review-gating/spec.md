# adversarial-review-gating Specification

## Purpose

Keep deterministic review mandatory and treat model critique as optional evidence.
## Requirements
### Requirement: Model critique is optional evidence

The workflow MUST run deterministic lint first. It MUST run model critics only
when the user requests them or a concrete risk justifies them. A critic result
MUST NOT represent owner or peer approval.

#### Scenario: A concrete risk justifies critique

- **POLARITY** positive
- **WHEN** a phase names a risk that benefits from independent model critique
- **THEN** the skill runs its bounded critic loop and records the terminal state

#### Scenario: No critique is justified

- **POLARITY** negative
- **WHEN** the user did not request critique and no concrete risk justifies it
- **THEN** the phase records `not run` without waiver language

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
distinct records. Only the owner can set the review decision.

#### Scenario: A critic reaches CLEAN

- **POLARITY** positive
- **WHEN** no model objection survives
- **THEN** the task records model evidence without changing the owner decision

#### Scenario: A model attempts to approve

- **POLARITY** negative
- **WHEN** a model critic produces an owner or peer approval verdict
- **THEN** the workflow rejects that verdict as the wrong authority
