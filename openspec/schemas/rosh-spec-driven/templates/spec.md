## ADDED Requirements

### Requirement: <!-- requirement name -->
<!-- requirement text; use SHALL or MUST -->

<!-- rosh-spec-driven rule: every requirement needs at least one scenario
     declaring `- **POLARITY** negative`. A requirement with only happy paths
     does not say what happens when things go wrong. -->

#### Scenario: <!-- name the success path -->
- **POLARITY** positive
- **WHEN** <!-- condition -->
- **THEN** <!-- expected outcome -->

#### Scenario: <!-- name the failure path -->
- **POLARITY** negative
- **WHEN** <!-- the unexpected condition -->
- **THEN** <!-- the error, rejection, or refusal -->
