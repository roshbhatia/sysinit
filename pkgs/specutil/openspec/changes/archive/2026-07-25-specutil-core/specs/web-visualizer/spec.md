## ADDED Requirements

### Requirement: Static web dependency graph
The `web` verb SHALL produce a lightweight, static web site (a single HTML
document, no backend) that renders the cross-change dependency DAG from the
`graph.json` feed. The site's presentation layer (CSS framework, charting
library, graph runtime) SHALL load at view time from a version-pinned,
SRI-protected CDN, while the binary itself SHALL perform no network I/O; the
`graph.json` feed SHALL be inlined into the page rather than fetched.

#### Scenario: Static site renders the DAG
- **WHEN** the user runs `specutil web` and opens the site with network access
- **THEN** the workstream dependency graph is displayed, with the presentation
  layer loaded from the pinned CDN and the feed inlined

#### Scenario: Binary performs no network I/O
- **WHEN** the binary generates the site
- **THEN** it reads only local artifacts and makes no network request; only the
  rendered page fetches its presentation layer when later opened

#### Scenario: Empty graph renders gracefully
- **WHEN** there are no dependency edges
- **THEN** the site shows the changes (or an empty-state message) without erroring

### Requirement: Renderer-independent feed
The web layer SHALL consume the canonical `graph.json` such that the graph renderer
can change without altering the data feed's schema.

#### Scenario: Data feed independent of renderer
- **WHEN** the rendering approach changes
- **THEN** the same `graph.json` feed is consumed without modification to its schema
