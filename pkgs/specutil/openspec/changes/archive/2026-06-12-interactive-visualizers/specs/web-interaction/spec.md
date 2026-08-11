## ADDED Requirements

### Requirement: Self-contained interactive graph
The web visualizer SHALL render the dependency DAG with directed arrows and
support pan, zoom, and fit using a vendored graph library inlined into a single
HTML file. The page MUST remain self-contained and offline: no external
`<script src>` or `<link>` references and no network requests at view time. The
binary MUST add no network I/O and no build-time toolchain to produce it.

#### Scenario: Directed arrows rendered
- **WHEN** the page renders a graph with edges
- **THEN** each edge is drawn as a directed arrow from prerequisite to dependent

#### Scenario: Self-contained offline
- **WHEN** the generated HTML file is opened from the local filesystem with no
  network
- **THEN** the graph renders fully, with the graph library and all data inlined
  and no external resource references

#### Scenario: Pan, zoom, and fit
- **WHEN** the user pans, zooms, or invokes fit on the canvas
- **THEN** the view responds without reloading or fetching anything

### Requirement: Lifecycle styling and focus highlighting
Nodes SHALL be styled by lifecycle (proposed, active, archived) and convey
progress. When a node is selected or hovered, the page SHALL highlight its
connected edges and neighbors and de-emphasize the rest.

#### Scenario: Lifecycle color
- **WHEN** the graph renders
- **THEN** node appearance reflects each workstream's lifecycle and progress

#### Scenario: Focus on interaction
- **WHEN** the user selects or hovers a node
- **THEN** its connected edges and neighbors are highlighted and unrelated nodes
  are dimmed

### Requirement: Clickable ticket drawer
Clicking a node SHALL open a drawer showing that workstream's lifecycle,
progress, proposal why and what-changes, tasks grouped by phase with done
indicators, and its depends-on and blocks relationships rendered as clickable
chips that re-focus the graph on the referenced workstream.

#### Scenario: Open drawer with detail
- **WHEN** the user clicks a node
- **THEN** a drawer opens showing that workstream's lifecycle, progress, why,
  what-changes, and tasks-by-phase from the inlined detail feed

#### Scenario: Navigate via relationship chip
- **WHEN** the user clicks a depends-on or blocks chip in the drawer
- **THEN** the graph re-focuses on the referenced workstream and its drawer opens

### Requirement: Node search
The page SHALL let the user search or filter nodes by name and focus a match.

#### Scenario: Search focuses a node
- **WHEN** the user enters a query that matches a node label
- **THEN** the matching node is highlighted and brought into view

### Requirement: Graceful empty and edgeless states
The page SHALL render readable guidance rather than a broken or empty canvas
when there are no workstreams, or when workstreams exist but no dependency edges
are defined, including how to seed dependencies.

#### Scenario: No workstreams
- **WHEN** the graph has no nodes
- **THEN** the page shows guidance on defining workstreams instead of an empty
  canvas

#### Scenario: Workstreams without edges
- **WHEN** nodes exist but no edges are defined
- **THEN** the nodes still render and the page indicates how to seed
  dependencies (e.g. via `graph --suggest`)
