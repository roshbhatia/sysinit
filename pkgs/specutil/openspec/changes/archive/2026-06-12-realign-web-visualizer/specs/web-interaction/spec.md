## ADDED Requirements

### Requirement: Static CDN-backed visualizer
The web visualizer SHALL render a static page whose presentation layer (a CSS
framework and a charting library) loads at view time from a **version-pinned**
CDN with Subresource Integrity hashes, `crossorigin`, and an `onerror` handler so
a supply-chain swap cannot execute and an offline open degrades loudly. The data
feeds (graph and detail) and the cross-change dependency DAG SHALL be inlined into
the page — no data file is ever fetched. The cross-change DAG SHALL be drawn as a
**static inline SVG** with directed arrows from prerequisite to dependent; the
page does NOT provide pan, zoom, or fit. The binary itself MUST perform no network
I/O and add no build-time toolchain to produce the page.

#### Scenario: Directed arrows rendered
- **WHEN** two or more changes exist and the overview renders a graph with edges
- **THEN** each edge is drawn as a directed arrow, in inline SVG, from prerequisite
  to dependent

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
- **THEN** an overview with a lifecycle tally, the inline-SVG dependency graph, and
  per-change cards renders, and selecting a change navigates to its document

#### Scenario: Navigate via relationship chip
- **WHEN** the user clicks a depends-on or blocks chip in a change's document
- **THEN** the page navigates to the referenced change's document

## MODIFIED Requirements

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

## REMOVED Requirements

### Requirement: Self-contained interactive graph
**Reason**: Replaced by "Static CDN-backed visualizer". The vendored, fully-offline,
pan/zoom/fit interactive canvas was dropped in favor of a static document-first page
whose presentation layer loads from a pinned, SRI-protected CDN while the binary
stays network-free.
**Migration**: The dependency graph still renders (as a static inline SVG with
directed arrows on the multi-change overview); pan/zoom/fit are gone. Open the page
with network access for the styled presentation layer, or accept the loud offline
notice when opening from `file://` with no network.

### Requirement: Lifecycle styling and focus highlighting
**Reason**: Narrowed to "Lifecycle styling and progress". Focus highlighting on
hover/select required an interactive canvas, which the static document-first design
no longer has.
**Migration**: Lifecycle and progress are still conveyed (badges, progress meters,
cards); follow relationships via the clickable depends-on/blocks chips instead of
hover highlighting.

### Requirement: Clickable ticket drawer
**Reason**: Folded into "Readable per-change document". The drawer was an artifact of
the interactive-canvas design; a change's detail is now the page itself (single
change) or a hash-routed document (several changes).
**Migration**: Open a change's document directly (single change) or select it from
the overview / follow a depends-on/blocks chip (several changes); the same lifecycle,
progress, why, what-changes, and tasks-by-phase content is shown inline.

### Requirement: Node search
**Reason**: A single readable document, or a small card grid for a handful of
changes, does not warrant in-page search; the feature added interactive-canvas weight
the redesign removed.
**Migration**: Use the overview card grid and depends-on/blocks chips to navigate
between changes; the browser's native in-page find covers text lookup.
