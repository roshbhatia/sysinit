## MODIFIED Requirements

### Requirement: Deterministic detail projection
The system SHALL provide a `detail.json` projection of the loaded IR, keyed by
change name, carrying per-change lifecycle, progress, proposal why and
what-changes, and tasks grouped by phase with their done state and their kind
(plain, verify, apply, or confirm). The projection MUST be pure and deterministic:
identical inputs yield byte-identical output.

#### Scenario: Detail emitted for each change
- **WHEN** the detail projection runs over a set of loaded changes
- **THEN** the output contains one entry per change, keyed by change name, with
  its lifecycle, numeric progress (done/total), why, what-changes, and an
  ordered list of phases each containing ordered task items with text, done
  state, and kind

#### Scenario: Task kind carried through
- **WHEN** a change's tasks include items classified as verify, apply, or confirm
- **THEN** each item in the projection carries its kind, so consuming surfaces mark
  it without re-parsing the source markdown

#### Scenario: Deterministic output
- **WHEN** the detail projection runs twice over identical inputs
- **THEN** the two outputs are byte-identical
