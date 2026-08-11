## ADDED Requirements

### Requirement: Switchable board and graph views
The web page SHALL offer a board view and a dedicated graph view in addition to the
existing overview and per-change document, switchable in place without a page reload. The
board SHALL lay changes out in lifecycle columns (proposed, active, archived), each change
a card conveying its lifecycle and progress. The graph view SHALL present the cross-change
dependency DAG full-width as the binary-emitted static inline SVG. For a single change the
page SHALL still land directly on that change's document; for two or more changes the page
SHALL land on the existing overview (lifecycle tally and cards), with the board and graph
reachable as additional views. Each view SHALL be reachable by an in-page hash route so a
specific view is deep-linkable. The page MUST NOT introduce pan, zoom, fit, or any vendored
interactive-graph library to provide these views.

#### Scenario: Board groups changes by lifecycle
- **WHEN** two or more changes exist and the user switches to the board view
- **THEN** changes are grouped into proposed / active / archived columns, each card
  showing the change's lifecycle and a progress indicator, and selecting a card navigates
  to that change's document

#### Scenario: Overview remains the multi-change landing
- **WHEN** two or more changes exist and the page opens
- **THEN** it lands on the existing overview (lifecycle tally and cards), and the board and
  graph are reachable as additional views

#### Scenario: Dedicated graph view
- **WHEN** the user switches to the graph view and edges exist
- **THEN** the cross-change dependency DAG renders as a static inline SVG with directed
  arrows from prerequisite to dependent, without pan/zoom/fit

#### Scenario: Views are deep-linkable
- **WHEN** the page is opened at a view's hash route (board, graph, or a change document)
- **THEN** that view renders directly

### Requirement: Clickable, lifecycle-colored graph nodes
In the graph view each node SHALL be colored by its change's lifecycle and SHALL be a
navigation control that opens that change's document when activated. Selecting or hovering
a node SHALL emphasize its incident edges and immediate neighbors and de-emphasize
unrelated nodes, achieved without a scripting-dependent canvas so the graph still renders
and navigates with scripting disabled.

#### Scenario: Node reflects lifecycle and navigates
- **WHEN** the graph view renders a node and the user activates it
- **THEN** the node's appearance reflects its change's lifecycle and activating it
  navigates to that change's document

#### Scenario: Incident emphasis on focus
- **WHEN** the user hovers or targets a node in the graph view
- **THEN** that node's incident edges and immediate neighbors are emphasized and unrelated
  nodes are de-emphasized

### Requirement: System-synced light and dark theme
The page SHALL support light and dark themes. By default it SHALL follow the operating
system preference via `prefers-color-scheme`, and SHALL provide a control to override the
theme (auto, light, dark) with the choice persisted across reloads. All page colors,
including the inline-SVG dependency graph and the progress chart, SHALL track the active
theme. The initial theme MUST be applied before first paint so there is no flash of the
wrong theme.

#### Scenario: Follows system preference by default
- **WHEN** the page is opened with no stored override
- **THEN** it renders in the theme matching the operating system's light/dark preference

#### Scenario: Manual override persists
- **WHEN** the user sets the theme override and reloads the page
- **THEN** the page renders in the chosen theme, and the inline-SVG graph and chart colors
  match it

### Requirement: Relationships beside the task checklist
In a change's document the depends-on and blocks relationships SHALL be presented adjacent
to the tasks-by-phase checklist (a side rail beside the checklist on wide viewports,
collapsing to a stacked layout when narrow), so dependencies are read together with the
work rather than separated from it. The relationships SHALL remain clickable chips that
navigate to the referenced change's document and SHALL continue to be derived from the
dependency graph edges.

#### Scenario: Relationships shown alongside tasks
- **WHEN** a change's document renders on a wide viewport
- **THEN** its depends-on and blocks chips appear beside the tasks-by-phase checklist, not
  only below it, and clicking a chip navigates to the referenced change's document

#### Scenario: Narrow viewport stacks gracefully
- **WHEN** the same document renders on a narrow viewport
- **THEN** the relationships and the checklist stack into a single readable column

### Requirement: Surfaced manifest diagnostics
The page SHALL surface manifest diagnostics (cycles or dangling references) in a visible
health banner rather than discarding them, so a broken manifest is apparent in the web
visualizer.

#### Scenario: Cycle or dangling edge is shown
- **WHEN** the manifest contains a cycle or a dangling reference
- **THEN** the page shows a visible diagnostic banner naming the kind of problem

#### Scenario: Clean manifest shows no banner
- **WHEN** the manifest has no diagnostics
- **THEN** no diagnostic banner is shown

### Requirement: Task-kind markers and cross-change roll-up
Checklist items SHALL be marked by their kind (verify, apply, confirm) where classified,
so impactful and confirmation steps are distinguishable from plain tasks. The multi-change
overview SHALL additionally show a cross-change roll-up of overall completed-versus-total
tasks across all changes alongside the lifecycle tally.

#### Scenario: Kind markers on items
- **WHEN** a change's document renders a checklist whose items include verify/apply/confirm
  tasks
- **THEN** those items carry a marker distinguishing their kind from plain tasks

#### Scenario: Overall progress roll-up
- **WHEN** the multi-change overview renders
- **THEN** it shows the aggregate completed-versus-total task count across all changes
