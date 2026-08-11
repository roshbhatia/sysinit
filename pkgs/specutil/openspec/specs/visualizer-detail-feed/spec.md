# visualizer-detail-feed Specification

## Purpose
TBD - created by archiving change interactive-visualizers. Update Purpose after archive.
## Requirements
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

### Requirement: Graph feed remains the pure dependency contract
The `graph.json` feed SHALL continue to carry only nodes and edges and MUST NOT
be expanded with task-level detail. Dependency relationships (`dependsOn`,
`blocks`) consumed by detail views SHALL be derived from `graph.json` edges
rather than duplicated into the detail projection.

#### Scenario: Graph schema unchanged
- **WHEN** the graph feed is produced for a change set
- **THEN** each node carries only id and label and each edge carries only from
  and to, with no embedded task data

### Requirement: Shared lifecycle and progress classification
The system SHALL classify a workstream's lifecycle (proposed, active, archived)
and progress from task done state in a single shared component consumed by every
surface, so no two surfaces report different states for the same change.

#### Scenario: Identical classification across surfaces
- **WHEN** the detail projection and the web view classify the same change
- **THEN** both report the same lifecycle and the same progress value

