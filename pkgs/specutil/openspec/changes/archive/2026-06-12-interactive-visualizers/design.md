## Context

specutil already normalizes openspec change artifacts into a rich in-memory IR
(proposal why/what, specs, design, tasks→phases→items with done state) and
projects a workstream-level dependency DAG to `graph.json`, Mermaid, and DOT.
Two visualizers consume that work: a bubbletea TUI (kanban + layered-depth graph
view) that imports the IR Go package directly, and a `serve` command that emits
a single self-contained offline HTML file rendering the DAG with inlined
Mermaid. The determinism boundary is strict: the binary performs no network I/O
(enforced by a guard test), so `serve` writes a static artifact rather than
running a server.

Both visualizers stop at the workstream boundary. The TUI captures
`tea.WindowSizeMsg` width/height but `View()` ignores them (fixed
`JoinHorizontal`), so it neither resizes nor scrolls. Its graph view lists edges
as text and never highlights relationships for a focused node. The web page
renders nodes but offers no drill-down. Neither surface exposes the per-task
detail that already exists in the IR. The user asked for auto-resize, visible
relationships, and click-to-open ticket detail on both surfaces.

## Goals / Non-Goals

**Goals:**
- Surface task-level detail ("ticket") on demand in both the TUI and the web,
  sourced from the existing IR — no new parsing.
- Make relationships legible without free-form edge spaghetti.
- Make the TUI responsive to terminal size.
- Give the web real directed arrows, pan/zoom, lifecycle styling, and
  click-to-detail.
- Keep one consistent interaction model across both surfaces (focus+context +
  ticket panel) so the mental model transfers.
- Preserve the determinism boundary: no network I/O, single-file offline web, no
  native API clients, byte-deterministic projections.

**Non-Goals:**
- No React/shadcn/Vite build toolchain added to the Go module.
- No editing of artifacts from the visualizers — both remain read-only viewers.
- No new graph layout for the TUI beyond the existing layered-depth columns.
- No live/streaming updates; the web file is a static snapshot.
- No remote sync changes (Linear/Notion) — out of scope.

## Decisions

### 1. Add a separate `detail.json` projection; keep `graph.json` pure
The detail need is per-change content; the graph feed is the dependency
contract. Folding tasks into graph nodes would muddy the renderer-independent
DAG. Instead emit a second deterministic projection — `detail.json` — keyed by
change name, carrying lifecycle, progress, why, what-changes, and
phases→tasks(done). The web inlines both as data islands in the one HTML file;
the TUI ignores both and reads the IR directly. `dependsOn`/`blocks` are derived
client-side from `graph.json` edges, so detail never duplicates edge data.
*Rejected:* enriching graph nodes with a `tasks[]` array — couples presentation
detail into the dependency contract and breaks the "graph.json is the feed"
story.

### 2. Web stack: Cytoscape.js (vendored single file), not shadcn/React
The web visualizer is a read-only DAG viewer. Cytoscape.js ships as one
vendored JS file (like the current Mermaid bundle), keeps the page
self-contained and offline, and needs no build step — so the determinism
boundary and the `buildGoModule` toolchain are untouched. It provides what
Mermaid cannot: real directed arrows, pan/zoom/fit, dagre layered layout,
per-node styling, and click/hover events for drill-down. This is the exact
drop-in `specutil-core` design.md pre-planned ("Cytoscape.js is a drop-in later
if task-level drill-down is needed"). *Rejected:* shadcn + React Flow — adds a
node/npm/Vite build derivation, vendored node deps, and two-language CI to a Go
CLI; its component strengths (forms, stateful UI) are unused by a read-only
viewer. The polish it buys (a drawer, badges, chips) is ~150 lines of hand-rolled
CSS. *Rejected:* staying on Mermaid — no click events, no pan/zoom, static SVG.

### 3. Relationships via focus+context, not drawn arrows (TUI)
Free-form ASCII edge routing across an arbitrary DAG produces crossing-line
noise that degrades with graph size. Instead: position already encodes direction
(prereqs left, dependents right via depth columns); on selection, highlight the
focused node's in/out edges and immediate neighbors, dim everything else, and
list "Depends on / Blocks" explicitly in the ticket panel. This is the proven
terminal pattern (lazygit/k9s). The web uses the same focus+context model on the
Cytoscape canvas, so the interaction is consistent across surfaces. *Rejected:*
always-on box-drawing connectors between all columns — spaghetti at scale.

### 4. Shared lifecycle/progress classifier
Node color (proposed/active/archived) and progress are derived from task done
state. The TUI already computes this in `lifecycle.go`. Lift it into a shared
`internal/lifecycle` package consumed by both the TUI and the `detail.json`
projection so the two surfaces never disagree about a workstream's state.

### 5. Master-detail ticket panel on both surfaces
TUI: a side/overlay pane (scrollable via `bubbles/viewport`) opened on
Enter/click, closed on Esc, showing lifecycle badge, progress bar, why/what,
tasks-by-phase with done glyphs, depends-on/blocks. Web: a slide-in right-hand
drawer with the same content and clickable depends-on/blocks chips that re-focus
the graph. Same information architecture, surface-appropriate chrome.

### 6. Responsive TUI layout
Recompute layout on every `WindowSizeMsg`: flex column widths to terminal width,
wrap/scroll vertical overflow via a viewport, and degrade gracefully to a single
column / list when too narrow. The captured `width/height` (currently dead
fields) become the layout inputs.

## Risks / Trade-offs

- **Cytoscape bundle size / vendoring.** Adds a second vendored JS asset; the
  page grows. Mitigation: it is still one offline file, embedded via `embed.FS`;
  the existing "self-contained, no external `<script src>`" tests extend to it.
  Vendored upstream content is not auto-updated (sync-script convention).
- **Overturning design.md decisions.** Reversing the Cytoscape/Mermaid call and
  extending the TUI graph decision could read as churn. Mitigation: both moves
  happen at their *documented* trigger conditions and are recorded here with
  rationale and rejected alternatives.
- **No edges to draw without a manifest** (e.g. sysinit). The relationship
  features render nothing useful until a manifest exists. Mitigation: graceful
  empty/flat-state messaging and pointing the flow at `graph --suggest`; this is
  a data concern, not a rendering bug.
- **Two data islands in one file.** Slightly larger payload and a client-side
  join. Mitigation: both are deterministic JSON; the join is by stable change
  name; payload stays well within a static-file budget.
- **TUI detail for long content.** Proposal why/what can be long. Mitigation:
  viewport scrolling and truncation; the TUI is a viewer, not a reader of full
  documents.
