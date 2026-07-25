## REMOVED Requirements

### Requirement: The deterministic rubric-lint stays mandatory
**Reason**: The requirement named `specreview` as the enforcer in its scenario titles, and that tool no longer exists. It is replaced by an equivalent requirement naming the rubric rather than one implementation.
**Migration**: No behavior changes. The same rubric now runs as `specutil check <change-dir>`; see the replacement requirement below.

## ADDED Requirements

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
