# web-interaction Specification

## Purpose
TBD - created by archiving change interactive-visualizers. Update Purpose after archive.
## Requirements
### Requirement: Graceful empty and edgeless states
The page SHALL render readable guidance rather than a broken or empty view when
there are no changes, or when changes exist but no dependency edges are defined,
including how to seed dependencies.

#### Scenario: No changes
- **WHEN** there are no changes
- **THEN** the page shows guidance on defining changes instead of an empty view

#### Scenario: Changes without edges
- **WHEN** changes exist but no edges are defined
- **THEN** the changes still render (as a document or cards) and the page indicates
  how to seed dependencies (e.g. via `graph --suggest`) instead of drawing an empty
  graph

### Requirement: Static CDN-backed visualizer
The web visualizer SHALL render a static page whose presentation layer (a CSS
framework and a charting library) loads at view time from a **version-pinned**
CDN with Subresource Integrity hashes, `crossorigin`, and an `onerror` handler so
a supply-chain swap cannot execute and an offline open degrades loudly. The data
feeds (graph and detail) SHALL be inlined into the page — no data file is ever
fetched. The cross-change DAG SHALL be drawn with directed arrows from prerequisite
to dependent. The binary itself MUST perform no network I/O and add no build-time
toolchain to produce the page.

#### Scenario: Directed arrows rendered
- **WHEN** two or more changes exist and the graph view renders edges
- **THEN** each edge is drawn as a directed arrow from prerequisite to dependent

#### Scenario: Presentation layer loads from a pinned CDN
- **WHEN** the page is opened with network access
- **THEN** its CSS framework and charting library load from version-pinned CDN URLs
  carrying SRI integrity hashes and `crossorigin`, while the graph and detail data
  are read from inlined literals

#### Scenario: Offline open degrades loudly
- **WHEN** the page is opened with no network access
- **THEN** the inlined content still renders and the page shows a visible offline
  notice rather than silently failing, because the CDN `onerror` fallback fires

#### Scenario: Binary performs no network I/O
- **WHEN** the binary generates the page
- **THEN** it reads only local artifacts and makes no network request; only the
  rendered page fetches its presentation layer when later opened

### Requirement: Lifecycle styling and progress
Each change SHALL be styled by lifecycle (proposed, active, archived) and convey
completion progress. The single-change document and the multi-change overview cards
SHALL both reflect lifecycle and progress.

#### Scenario: Lifecycle color
- **WHEN** the page renders a change
- **THEN** its appearance reflects that change's lifecycle and a progress indicator
  conveys completed-versus-total tasks

### Requirement: Readable per-change document
For a single change the page SHALL land directly on that change's readable task
document, showing its lifecycle, progress, proposal why and what-changes, and tasks
grouped by phase with done indicators. For two or more changes the page SHALL show
an overview (lifecycle tally and change cards) and reach each change's document by
in-page hash navigation. A change's depends-on and blocks relationships SHALL be
rendered as clickable chips that navigate to the referenced change's document.

#### Scenario: Single change lands on its document
- **WHEN** exactly one change exists and the page opens
- **THEN** the change's task document renders directly, with lifecycle, progress,
  why, what-changes, and tasks-by-phase from the inlined detail feed

#### Scenario: Several changes show an overview
- **WHEN** two or more changes exist and the page opens
- **THEN** an overview with a lifecycle tally and per-change cards renders, and selecting
  a change navigates to its document

#### Scenario: Navigate via relationship chip
- **WHEN** the user clicks a depends-on or blocks chip in a change's document
- **THEN** the page navigates to the referenced change's document

### Requirement: Switchable board and graph views
The web page SHALL offer a board view and a dedicated graph view in addition to the
existing overview and per-change document, switchable in place without a page reload. The
board SHALL lay changes out in lifecycle columns (proposed, active, archived), each change
a card conveying its lifecycle and progress. The graph view SHALL present the cross-change
dependency DAG full-width. For a single change the page SHALL still land directly on that
change's document; for two or more changes the page SHALL land on the existing overview
(lifecycle tally and cards), with the board and graph reachable as additional views. Each
view SHALL be reachable by an in-page hash route so a specific view is deep-linkable. The
graph runtime SHALL load from a version-pinned CDN reference carrying an SRI integrity
hash; it MUST NOT be vendored into the repository.

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
- **THEN** the cross-change dependency DAG renders with directed arrows from prerequisite
  to dependent

#### Scenario: Views are deep-linkable
- **WHEN** the page is opened at a view's hash route (board, graph, or a change document)
- **THEN** that view renders directly

### Requirement: Graph laid out in dependency levels
The graph view SHALL group its nodes into levels, where a node's level is the length of the
longest chain of prerequisites that must finish first. Every node at one level can therefore
be worked in parallel. Each level SHALL be drawn as a labeled container naming its ordinal
and its size, and SHALL also be listed in a text roster so the same model is readable
without a pointer. The view SHALL state, before the diagram, how many changes are ready to
start, how many levels deep the graph runs, and how many changes sit on the critical path.

#### Scenario: Parallel work is a visible group
- **WHEN** three changes share a single prerequisite and nothing else blocks them
- **THEN** all three render inside one level container labeled with the count, and each is
  listed under the same level in the roster

#### Scenario: Ready work is named up front
- **WHEN** a change has no outstanding prerequisites and no completed tasks
- **THEN** it is counted as ready to start and named in the lede before the diagram

#### Scenario: Critical path is marked
- **WHEN** the graph has at least one edge
- **THEN** the changes on the longest dependency chain are marked in both the diagram and
  the roster, and their count is stated in the lede

### Requirement: Task-level graph grain
The graph view SHALL offer two grains: tasks (the default) and changes. The task grain
SHALL lay out every change's tasks as nodes grouped in a container per change, columned by
each task's dependency level; a task's level SHALL account for both the sequential order of
its phases and any declared task-to-task dependency, so a phase that names no dependency
still renders as a strictly sequential chain while one that does reveals its internal
parallelism. The changes grain SHALL collapse each change to a single summary node. A
control SHALL switch between the two grains without a page reload, and the choice SHALL
persist across a single graph-view session.

#### Scenario: Declared task dependency reveals parallelism
- **WHEN** two tasks in the same phase both depend only on an earlier task in that phase and
  not on each other
- **THEN** the task grain places them at the same level, distinct from the phase's other
  tasks

#### Scenario: Undeclared dependencies default to sequential
- **WHEN** a phase's tasks declare no dependency field
- **THEN** the task grain renders them as a strictly sequential chain, one per level

#### Scenario: Cross-change edges connect change groups, not tasks
- **WHEN** the task grain renders a manifest dependency between two changes
- **THEN** the edge connects the two changes' container nodes, not a specific task in either

### Requirement: Clickable, readiness-colored graph nodes
In the graph view each node SHALL be colored by its work readiness — done, in progress,
blocked, ready, or waiting — derived from the change's lifecycle together with whether its
prerequisites are complete. Each node SHALL be a navigation control that opens that
change's document when activated. Hovering a node SHALL emphasize its incident edges and
immediate neighbors, de-emphasize unrelated nodes, and populate an inspector panel with
that change's progress, next task, blockers, and downstream changes.

#### Scenario: Node reflects readiness and navigates
- **WHEN** the graph view renders a node and the user activates it
- **THEN** the node's appearance reflects its readiness and activating it navigates to that
  change's document

#### Scenario: Blocked and satisfied edges are distinguishable
- **WHEN** one prerequisite is complete and another is not
- **THEN** the satisfied edge and the still-blocking edge render with different styling

#### Scenario: Incident emphasis on focus
- **WHEN** the user hovers a node in the graph view
- **THEN** that node's incident edges and immediate neighbors are emphasized, unrelated
  nodes are de-emphasized, and the inspector shows that change's detail

### Requirement: System-synced light and dark theme
The page SHALL support light and dark themes. By default it SHALL follow the operating
system preference via `prefers-color-scheme`, and SHALL provide a control to override the
theme (auto, light, dark) with the choice persisted across reloads. All page colors,
including the dependency graph and the progress chart, SHALL track the active
theme. The initial theme MUST be applied before first paint so there is no flash of the
wrong theme.

#### Scenario: Follows system preference by default
- **WHEN** the page is opened with no stored override
- **THEN** it renders in the theme matching the operating system's light/dark preference

#### Scenario: Manual override persists
- **WHEN** the user sets the theme override and reloads the page
- **THEN** the page renders in the chosen theme, and the graph and chart colors match it

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

