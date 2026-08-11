## Why

The merged `web-interaction` spec mandates a vendored, fully-offline, interactive
graph canvas — pan/zoom/fit, a click-to-open ticket drawer, and node search — built
on an inlined graph library. The shipped web viewer was deliberately reworked to
prioritize readability: a clean per-change task **document**, a presentation layer
(Pico CSS + Chart.js) loaded from a pinned, SRI-protected CDN, and a static inline
SVG dependency graph. The spec now actively contradicts the binary's behavior, so
the capability must be realigned with what ships.

## What Changes

- **MODIFIED** `web-interaction` — the page is a static document, not an interactive
  canvas:
  - For a single change, the page lands directly on that change's readable task
    document (lifecycle, progress, why/what-changes, tasks grouped by phase).
  - For two or more changes, the page shows an overview (lifecycle tally, change
    cards) and renders the cross-change dependency DAG as a **static inline SVG**
    with directed arrows; per-change documents are reached by hash-routed
    navigation, with depends-on/blocks rendered as clickable chips.
  - The presentation layer (Pico CSS, Chart.js per-phase progress bar) loads from a
    **version-pinned CDN** with SRI integrity hashes, `crossorigin`, and an
    `onerror` fallback that surfaces a loud offline warning.
  - Lifecycle styling and progress are retained; interactive focus highlighting on
    hover/select is dropped (there is no interactive canvas).
  - The binary continues to perform **zero network I/O** and adds no build-time
    toolchain — only the rendered page fetches its presentation layer at view time.
- **REMOVED** the node-search requirement — a single readable document (or a small
  card grid) needs no in-page search.
- **BREAKING**: the page no longer renders fully offline from `file://` with no
  network. Opening offline degrades loudly (an offline notice) rather than rendering
  the full presentation layer.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `web-interaction`: drop the vendored/offline/interactive-canvas, drawer, focus
  highlighting, and node-search requirements; replace with a static, document-first
  viewer whose presentation layer loads from a pinned SRI CDN while the binary stays
  network-free.

## Impact

- `internal/web/` (already implemented): `page.html.tmpl` rewritten; `web.go` emits
  an inline SVG DAG; six vendored runtime assets deleted.
- `internal/guard/guard_test.go` (already implemented): `TestWebRuntimeIsPinnedCDN`
  inverts the old vendoring guard — old bundles must be gone, CDN tags must be
  pinned + SRI + `crossorigin` + `onerror`; `TestNoNetworkImportsInBinary` still
  guards the binary.
- `internal/cli/root.go`: `serve` help text describes the new design.
- Follow-up: the still-active `specutil-core` change carries a `web-visualizer`
  delta requiring Mermaid rendering and full offline operation, which this realigned
  behavior also supersedes. That delta must be reconciled before `specutil-core`
  archives so it does not re-merge the contradiction.
