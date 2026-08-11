## Context

Two visualizers consume the same IR:

- `internal/web` renders a single static HTML file with two inlined feeds (`GRAPH`
  = nodes+edges, `DETAIL` = per-change lifecycle/progress/why/what-changes/phases) and
  a binary-emitted inline-SVG DAG. Presentation (Pico CSS + Chart.js) loads from a
  version-pinned, SRI-protected CDN. The page is hash-routed and `file://`-safe. It is
  **light-only** (`body{background:#fff}`, hardcoded SVG fills) and has neither a board
  nor a dedicated graph view; relationships are chips below the checklist.
- `internal/tui` (bubbletea + bubblezone + lipgloss) already has a lifecycle kanban
  (`viewKanban`), a depth-layered graph (`viewGraph`) with `neighbors()` focus+context
  highlighting, and a master-detail panel — but uses hardcoded ANSI-256 colors, thin
  cards (`name` + `N/M tasks`), and stacks relationships at the bottom of the panel.

Shared classification (`internal/lifecycle`: `Classify`, `Progress`, `Order`) and the
depth layering (`internal/tui/layout.go: layers`, `internal/graph`) already guarantee
the two surfaces agree on lifecycle, progress, and column order. `ir.TaskItem` already
carries `Kind` (verify/apply/confirm); `internal/detail` does not yet propagate it.

The realigned `web-interaction` spec (`realign-web-visualizer`, tasks complete but not
yet archived) established the static, document-first, pinned-CDN design and explicitly
removed the old vendored interactive canvas (pan/zoom/fit), focus highlighting, and node
search. This change must respect that boundary while adding back *lightweight*
interactivity that does not need a canvas.

## Goals / Non-Goals

**Goals**
- Both surfaces offer a board (lifecycle columns) and a graph (depth layers) view, plus a
  per-change document/detail, switchable in place.
- Relationships (depends-on / blocks) read *beside* the task checklist on both surfaces.
- Theme follows the system: web via `prefers-color-scheme` + manual override; TUI via a
  terminal-background-adaptive palette.
- `serve` surfaces manifest diagnostics, task kinds, a cross-change roll-up, and
  deep-linkable views.
- The TUI looks finished: lifecycle color, inline progress, fixed layout math.

**Non-Goals**
- No vendored canvas, pan/zoom/fit, or new build toolchain (realign boundary holds).
- No binary network I/O; no new data files; graph feed stays pure.
- No task-level nodes in the graph.

## Decisions

### D1 — One change, three capabilities, shared model
Treat parity as a single change touching `web-interaction`, `tui-interaction`, and
`visualizer-detail-feed`, rather than two independent reworks. The two surfaces converge
on the same concepts (lifecycle columns, depth-layered graph, document with relationships
beside the checklist, task kinds). *Rejected*: separate web-only and tui-only changes —
they would re-derive the same model twice and risk drifting again.

### D2 — Web interactivity stays canvas-free
The board is plain CSS columns. The graph view keeps the **binary-emitted inline SVG**
but: (a) stamps each node with a lifecycle class (`class="node lc-active"` etc.) so CSS
owns the palette and dark mode just works; (b) wraps each node in
`<a href="#/c/<name>">` so clicking navigates — pure anchors, no JS, `file://`-safe;
(c) adds focus+context highlighting via CSS only — hovering/`:target`-ing a node dims
non-incident nodes/edges using sibling selectors and `data-` attributes; degrades to
"all visible" with JS/CSS off. *Rejected*: reintroducing a JS graph library — violates
the realign non-goal and adds weight.

### D3 — Theming via CSS custom properties + `data-theme`, JS only for the toggle
Move every color to `:root` custom properties with a `[data-theme="dark"]` override
block; default to `@media (prefers-color-scheme: dark)`. Pico CSS 2 already honors
`data-theme`, so we ride its tokens for built-ins and define our own vars for custom
components and the SVG. A small inline script sets `data-theme` from `localStorage` on
load (before paint, to avoid a flash) and cycles Auto→Light→Dark on toggle. Chart.js
colors are read from the resolved CSS variables and the chart is re-rendered on theme
change. *Rejected*: server-rendered theme (no system sync) and duplicate light/dark
stylesheets (drift).

### D4 — TUI theming via lipgloss adaptive colors
Replace hardcoded `lipgloss.Color("205")`-style codes with `lipgloss.AdaptiveColor{Light,
Dark}` (and a small named palette), so lipgloss/termenv pick the variant matching the
terminal background. This is the TUI analog of the web's system-synced theme — same
intent, surface-appropriate mechanism. *Rejected*: a manual TUI theme flag — the terminal
already advertises its background; honor it.

### D5 — Relationships beside the checklist
Web document becomes a two-column layout on wide viewports: main column = tasks-by-phase
checklist (+ a "ready / next" callout for the lowest incomplete phase); sticky side rail =
lifecycle badge + progress meter + per-phase chart + **Depends on / Blocks** chips.
Collapses to one column on narrow screens. TUI detail panel mirrors this: relationships
move up next to the task list (chips near the top of the panel, or a right sub-rail when
width allows) with per-phase mini-bars. Relationships are still *derived from graph edges*
(per `visualizer-detail-feed`), not duplicated into the detail feed.

### D6 — Task kind flows through the detail feed
Add `Kind string` to `detail.Item`, populated from `ir.TaskItem.Kind`. Both surfaces mark
verify/apply/confirm items (a small glyph/label). This is per-item data that legitimately
belongs in the detail projection (unlike graph data, which stays out). *Rejected*:
re-classifying kind in the renderers — the IR already did it; don't duplicate.

### D7 — Diagnostics are a render concern fed from `graph.Build`, not the detail feed
`runServe` currently does `g, _ := graph.Build(...)`, discarding the `[]Diagnostic`
(cycles, dangling). Thread them into `web.Render` and render a visible health banner.
Diagnostics are graph-level, not per-change, so they do **not** go in the detail feed and
keep the graph feed pure. The TUI already renders diagnostics; this brings the web to
parity.

## Risks / Trade-offs

- **Template size / complexity.** `page.html.tmpl` grows substantially (switcher, board,
  themed CSS, two-column doc, banner). Mitigation: keep it one file (the design
  constraint), factor CSS into clearly-commented sections, cover structure with tests.
- **CSS-only graph focus highlighting is limited** vs. the TUI's computed neighbor set —
  `:target`/`:hover` sibling selectors can emphasize incident edges but not arbitrary
  multi-hop context. Accept the simpler one-hop emphasis on the web; the TUI keeps its
  richer `neighbors()` logic.
- **Theme flash (FOUC).** Reading `localStorage` after CSS paints would flash. Mitigation:
  set `data-theme` in a tiny head script before the stylesheet applies.
- **Pinned-CDN guard scope.** `TestWebRuntimeIsPinnedCDN` must keep passing; new CDN tags
  (if any) must be pinned + SRI + `crossorigin` + `onerror`. Prefer adding no new CDN
  deps (theme + board are our own CSS).
- **Archive ordering** (see Open Questions) — MODIFYing realigned requirements before
  realign archives would fail validation, so web additions are authored as ADDED
  requirements.

## Migration

No user-facing migration. `serve` output is a superset: existing routes (`#/`, `#/c/<name>`)
still work; new routes (`#/graph`, board as the multi-change landing) are additive. The
binary's flags and the determinism/CDN contracts are unchanged. Theme defaults to system,
so existing users see dark mode automatically on dark systems.

## Open Questions

- **Archive order — RESOLVED.** `realign-web-visualizer` (tasks complete) is archived first
  so the deployed `web-interaction` spec reflects the static-CDN baseline; these additions
  layer on top. Web deltas are ADDED requirements, so the change validates regardless.
- **Board vs. card grid — RESOLVED.** The board is an *additional* switchable view; the
  existing overview (lifecycle tally + card grid + inline DAG) remains the multi-change
  landing. So the web has four views: Overview (landing), Board, Graph, and Document.
- **Whether `web-interaction` and `visualizer-detail-feed`/`tui-interaction` should
  eventually merge** into fewer capabilities (a deferred question from `realign`). Out of
  scope here; noted for a future consolidation.
