## Why

The v1 visualizers stop at the workstream boundary: the TUI graph view and the
`serve` web page show *which* changes exist and (when a manifest is present)
*which depend on which*, but neither lets you see *what is actually inside* a
workstream. The rich IR — proposal why/what, tasks grouped by phase with their
done state, lifecycle, progress — is computed and then discarded at the
projection boundary. In practice that means the browser graph renders as a flat
row of disconnected nodes with no way to drill in, and the TUI ignores the
terminal size it captures. Users asked for three things on both surfaces:
auto-resize, visible relationships, and click-to-open task detail "like a
ticket." All three reduce to one root cause — *stop throwing the IR away at the
edge* — so they are best solved together.

## What Changes

- Add a second deterministic projection, `detail.json`: the per-change IR subset
  (lifecycle, progress, why, what-changes, tasks-by-phase with done state)
  serialized as JSON. `graph.json` stays the pure, renderer-independent
  dependency feed — unchanged. `dependsOn`/`blocks` are derived client-side from
  `graph.json` edges, not duplicated into the detail feed.
- Lift workstream lifecycle + progress classification into a shared package so
  the TUI and the web compute identical states (no "active here, proposed there"
  drift).
- **TUI**: become responsive (consume the captured terminal width/height, reflow
  on resize, scroll long columns via a viewport); add focus+context relationship
  highlighting (select a node → highlight its in/out edges, dim the rest) while
  keeping the layered-depth columns; add a master-detail ticket panel (open on
  Enter/click, shows why/what, tasks-by-phase, depends-on/blocks; Esc closes).
- **Web**: replace the static Mermaid render with Cytoscape.js (still a single
  vendored file, still one self-contained offline HTML, still no build step):
  real directed arrows, pan/zoom/fit, dagre layered layout, lifecycle-colored
  nodes, focus+context edge highlighting, a slide-in ticket drawer with
  clickable depends-on/blocks chips, and node search. **No React/shadcn build
  toolchain** is added to the Go module.
- Ensure there is data to relate: when no manifest exists, the viewers degrade
  gracefully and the docs/flow point at `graph --suggest` to seed edges.

This overturns two earlier `specutil-core` design decisions on purpose, both at
their documented trigger points: (1) "defer Cytoscape until task-level
drill-down is needed" — it is now needed; (2) "TUI graph = columns, not edge
routing" — extended (not reversed) with focus highlighting, still no free-form
ASCII arrow routing. The determinism boundary (binary does no network I/O,
single-file offline web, no native API clients) is preserved.

## Capabilities

### New Capabilities

- `visualizer-detail-feed`: a deterministic `detail.json` projection of the IR
  (lifecycle, progress, why, what-changes, tasks-by-phase) plus a shared
  lifecycle/progress classifier consumed by every renderer.
- `tui-interaction`: responsive TUI layout, focus+context relationship
  highlighting, and a master-detail ticket panel.
- `web-interaction`: a Cytoscape.js single-file web visualizer with directed
  arrows, pan/zoom, lifecycle styling, a clickable ticket drawer, and search.

### Modified Capabilities

<!-- None: specutil-core is not yet archived, so tui-visualizer / web-visualizer
     have no canonical specs to delta against. These capabilities supersede the
     interactive portions of those specs once core is archived. -->

## Impact

- `internal/graph` (or a new `internal/detail`): the `detail.json` projection and
  schema.
- `internal/lifecycle` (new, shared): lifecycle + progress classification lifted
  out of the TUI.
- `internal/tui`: responsive layout engine, edge-highlight selection model,
  ticket detail pane (`bubbles/viewport`).
- `internal/web`: Cytoscape.js vendored asset, rewritten `page.html.tmpl`
  (drawer, search, focus highlighting), `Render` inlining both data islands.
- `internal/cli`: `serve` emits the detail feed alongside the graph; `graph`
  optionally emits `detail.json`.
- Determinism guard test and the existing web self-contained tests extend to the
  Cytoscape bundle.
- No new build-time dependencies for the Go module; no network I/O added.
