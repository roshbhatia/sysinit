## ADDED Requirements

### Requirement: Proposals name the human-owned decision

Every proposal MUST state which judgment remains with the owner. Automation
evidence and model critique MUST NOT represent that approval.

#### Scenario: Proposal states the owner judgment

- **POLARITY** positive
- **WHEN** a proposal is ready for review
- **THEN** its Behavior section names the human-owned decision

#### Scenario: Automation claims the decision

- **POLARITY** negative
- **WHEN** a proposal treats a passing command or model verdict as owner approval
- **THEN** review rejects the proposal
