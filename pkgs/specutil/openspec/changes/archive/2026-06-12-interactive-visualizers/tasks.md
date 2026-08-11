## 1. Shared lifecycle + detail feed (foundation)

- [x] 1.1 Lift lifecycle + progress classification out of `internal/tui` into a shared `internal/lifecycle` package; update the TUI to consume it (no behavior change)
- [x] 1.2 Add a `detail` projection: a deterministic per-change struct (name, lifecycle, progress done/total, why, what-changes, phases→items{text,done}) serialized to `detail.json`, keyed by change name
- [x] 1.3 Confirm `graph.json` schema is unchanged (nodes id/label, edges from/to only); add/extend a test asserting no task data leaks into the graph feed
- [x] 1.4 Unit tests: detail projection determinism (byte-identical on repeat) and lifecycle parity (TUI classifier and detail projection agree for the same change)
- [x] 1.5 `gofmt`/`gofumpt`; `nix develop -c go test ./...` green

## 2. TUI interaction

- [x] 2.1 Make the layout responsive: consume the captured width/height, recompute on every `WindowSizeMsg`, flex column widths, and degrade to a single column/list when too narrow
- [x] 2.2 Add vertical scrolling for overflowing columns and the detail pane (hand-rolled line-window offset instead of `bubbles/viewport`, to avoid adding a dependency)
- [x] 2.3 Add focus+context highlighting in the graph view: on selection, emphasize the node's in/out edges and immediate neighbors, dim unrelated nodes; keep layered-depth columns (no routed arrows)
- [x] 2.4 Add the master-detail ticket panel: open on Enter/click, show lifecycle badge, progress bar, why/what-changes, tasks-by-phase with done glyphs, depends-on/blocks; close on Esc
- [x] 2.5 Derive depends-on/blocks for the focused node from the graph edges
- [x] 2.6 Tests for layout reflow, selection highlight state, and detail-panel open/close; `go test ./...` green

## 3. Web interaction

- [x] 3.1 Vendor Cytoscape.js (+ dagre layout extension) as embedded assets, following the no-auto-update vendoring convention
- [x] 3.2 Update `web.Render` to inline both data islands: the graph feed and the new detail feed
- [x] 3.3 Rewrite `page.html.tmpl`: Cytoscape canvas with directed arrows, dagre layered layout, pan/zoom/fit, lifecycle-colored nodes with progress
- [x] 3.4 Add focus+context edge/neighbor highlighting on select/hover
- [x] 3.5 Add the slide-in ticket drawer (lifecycle, progress bar, why/what, tasks-by-phase, depends-on/blocks chips); chips re-focus the graph and open the referenced drawer
- [x] 3.6 Add node search/filter that highlights and centers a match
- [x] 3.7 Handle empty state and edgeless state with readable guidance (point at `graph --suggest`)
- [x] 3.8 Extend web tests: self-contained (no external `<script src>`/`<link>`), Cytoscape bundle inlined, both data islands present, script-breakout escaping, empty/edgeless states
- [x] 3.9 Extend the determinism guard test to the Cytoscape bundle; confirm the binary adds no network imports

## 4. Wire-up + validation

- [x] 4.1 `serve` emits the detail feed alongside the graph; `graph` optionally emits `detail.json`
- [x] 4.2 Update help text / docs for the new viewer behavior and the `graph --suggest` seeding flow
- [x] 4.3 `nix develop -c go test ./...`, `gofmt` (this Go flake ships no `formatter`), `nix flake check` green
- [x] 4.4 Manual validation: web change-dropdown + layered relationships + drawer + search + index/edgeless states opened in a browser; TUI logic covered by §2.6 tests (interactive resize/select pass is a manual run in a real TTY)
