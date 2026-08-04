## ADDED Requirements

### Requirement: Global contexts state the responsibility contract

Every generated global context MUST state human ownership, evidence before
handoff, independent maintainability, and the limit of model review.

#### Scenario: A harness receives global context

- **POLARITY** positive
- **WHEN** any covered harness context is evaluated
- **THEN** it contains every required responsibility rule

#### Scenario: A responsibility rule is missing

- **POLARITY** negative
- **WHEN** a rendered context omits a required responsibility rule
- **THEN** evaluation fails with the harness and missing rule named
