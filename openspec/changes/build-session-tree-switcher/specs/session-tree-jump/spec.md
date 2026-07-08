## ADDED Requirements

### Requirement: The picker opens in label-jump mode with a curated alphabet

The picker SHALL open in default (non-fuzzy) mode so each row shows a quick-select jump label
drawn from a curated, home-row-first `alphabet` (still omitting the movement keys the widget
reserves). Typing a row's label SHALL activate that row. The needs-attention nodes SHALL be
ordered first so they receive the earliest, easiest labels. Live panes SHALL be ordered ahead
of dormant sessions so the common jump targets fall within the reliably-labeled range.

#### Scenario: Labels are present on open and jump on type

- **WHEN** the user presses `SUPER+s`
- **THEN** each row shows a jump label and typing a row's label activates that node

#### Scenario: Needs-attention nodes get the easiest labels

- **WHEN** the picker opens with one or more actionable panes
- **THEN** those panes are ordered first and receive the earliest alphabet labels

#### Scenario: More nodes than the alphabet remain reachable

- **WHEN** the node count exceeds the alphabet length so some rows have no single-key label
- **THEN** those rows are still reachable via fuzzy filtering rather than being unselectable

### Requirement: Fuzzy filter is one keystroke away via the widget's toggle

The picker SHALL rely on WezTerm's built-in `/` toggle to enter fuzzy-filter mode; the design
SHALL NOT attempt to rebind that toggle (e.g. to `ctrl+f`), which the widget does not support.
Entering fuzzy mode SHALL filter against the label text per the filter capability.

#### Scenario: Slash enters filter mode

- **WHEN** the user presses `/` in the open picker
- **THEN** the picker switches to fuzzy-filter mode

#### Scenario: The unsupported toggle key does nothing harmful

- **WHEN** the user presses `ctrl+f` expecting a filter toggle
- **THEN** the picker does not crash and remains usable (the toggle remains `/`)
