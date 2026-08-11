## ADDED Requirements

### Requirement: Terminal-adaptive palette
The TUI SHALL style itself with a palette that adapts to the terminal's background
(light or dark) rather than fixed color codes, so it is legible on both light and dark
terminals. Lifecycle, selection, neighbor-emphasis, progress, and done states SHALL each
have a defined light and dark variant.

#### Scenario: Adapts to terminal background
- **WHEN** the TUI runs in a light terminal and in a dark terminal
- **THEN** its colors adapt to each background and remain legible, without the user
  configuring a theme

### Requirement: Lifecycle-styled progress cards
Each workstream card on the board and in the graph columns SHALL convey, beyond its name,
the change's lifecycle (by color) and its completion progress (an inline progress bar with
a done/total count). Cards MUST remain readable when the terminal is too narrow for
side-by-side columns.

#### Scenario: Card shows lifecycle and progress
- **WHEN** a workstream card renders
- **THEN** it shows the change name, a lifecycle-derived color, and an inline progress bar
  with its done/total task count

## MODIFIED Requirements

### Requirement: Master-detail ticket panel
The TUI SHALL open a detail panel for a selected workstream showing its lifecycle,
progress, proposal why and what-changes, tasks grouped by phase with done indicators and
per-phase progress, task-kind markers (verify/apply/confirm) on items, and its depends-on
and blocks relationships presented beside the task checklist rather than only below it.
The panel SHALL open on an explicit action (Enter or click) and close on Esc, and its
layout MUST NOT break the panel border when composed beside the board.

#### Scenario: Open ticket detail
- **WHEN** the user presses Enter or clicks a workstream card
- **THEN** a detail panel opens showing that workstream's lifecycle, progress, why,
  what-changes, tasks-by-phase with per-phase progress and kind markers, and its
  depends-on/blocks shown alongside the checklist

#### Scenario: Close ticket detail
- **WHEN** the user presses Esc with the detail panel open
- **THEN** the panel closes and focus returns to the board

#### Scenario: Composed layout stays intact
- **WHEN** the detail panel is composed beside the board on a wide terminal
- **THEN** both the board and the panel render within the available width without broken
  borders or clipped content
