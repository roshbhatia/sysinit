## ADDED Requirements

### Requirement: Responsive layout
The TUI SHALL reflow its layout to the current terminal dimensions, recomputing
on every resize event, and SHALL scroll content that exceeds the available
height rather than truncating or overflowing it.

#### Scenario: Reflow on resize
- **WHEN** the terminal is resized while the TUI is running
- **THEN** the layout recomputes to the new width and height without visual
  overflow or clipping

#### Scenario: Scroll overflowing content
- **WHEN** a column or detail pane contains more rows than the visible height
- **THEN** the content is scrollable and no rows are silently dropped

#### Scenario: Narrow terminal degradation
- **WHEN** the terminal is too narrow to show all columns side by side
- **THEN** the layout degrades gracefully (e.g. to a single column or list)
  instead of breaking

### Requirement: Focus and context relationship highlighting
When a workstream node is selected, the TUI SHALL highlight that node's incoming
and outgoing dependency edges and immediate neighbors and de-emphasize unrelated
nodes, while preserving the layered-depth column layout. The TUI MUST NOT draw
free-form routed edges across the whole graph.

#### Scenario: Highlight on selection
- **WHEN** a node is selected in the graph view
- **THEN** its prerequisite and dependent neighbors are emphasized and unrelated
  nodes are dimmed

#### Scenario: Direction preserved by position
- **WHEN** the graph view renders
- **THEN** prerequisites appear in earlier depth columns and dependents in later
  columns

### Requirement: Master-detail ticket panel
The TUI SHALL open a detail panel for a selected workstream showing its
lifecycle, progress, proposal why and what-changes, tasks grouped by phase with
done indicators, and its depends-on and blocks lists. The panel SHALL open on
an explicit action (Enter or click) and close on Esc.

#### Scenario: Open ticket detail
- **WHEN** the user presses Enter or clicks a workstream card
- **THEN** a detail panel opens showing that workstream's lifecycle, progress,
  why, what-changes, tasks-by-phase, and depends-on/blocks

#### Scenario: Close ticket detail
- **WHEN** the user presses Esc with the detail panel open
- **THEN** the panel closes and focus returns to the board
