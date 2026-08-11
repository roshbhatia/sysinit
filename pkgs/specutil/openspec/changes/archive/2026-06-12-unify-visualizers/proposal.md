## Why

`specutil` ships two visualizers off the same IR, but they have drifted apart and
neither is finished:

- **`serve` (web)** is document-first and light-only. It has a static inline-SVG
  dependency DAG on the overview, but **no board (kanban) view**, **no dedicated
  graph view**, **no dark/light theming**, and it shows a change's depends-on/blocks
  as chips buried *below* the task checklist instead of *beside* it. It also silently
  drops manifest diagnostics (cycles, dangling edges) that the binary already computes.
- **`tui`** already has both a lifecycle kanban and a depth-layered graph with
  focus+context highlighting and a master-detail ticket panel — but it **looks bad**:
  hardcoded ANSI-256 colors that ignore the terminal's light/dark background, cards
  that show only a name and a bare `N/M tasks` count (no progress bar, no lifecycle
  color, no phase breakdown), relationships stacked at the very bottom of the detail
  panel, and no surfacing of task kind (verify/apply/confirm).

The two surfaces render the same `change` and should feel like the same product. A
reader should get the relationships *alongside* the checklist, see lifecycle at a
glance, and switch between a board and a graph in either surface. The theme should
follow the system (light/dark) automatically.

## What Changes

Bring the web and TUI visualizers to **parity around one shared model**, and finish
both:

- **Web gains a board view and a graph view.** A top-level view switcher (Board /
  Graph / per-change Document) mirrors the TUI's tab toggle. The board lays changes
  out in lifecycle columns (proposed / active / archived) as progress-bearing cards;
  the graph view promotes the existing inline-SVG DAG to a full-width, lifecycle-colored,
  click-to-navigate view. For a single change the page still lands on its document.
- **Relationships render beside the task checklist.** In a change's document (web) and
  in the TUI's detail panel, depends-on / blocks sit in a rail next to the
  tasks-by-phase checklist rather than below it, so dependencies are read together with
  the work.
- **System-synced theming.** The web page defaults to `prefers-color-scheme` with a
  manual Auto/Light/Dark toggle persisted to `localStorage`; all colors (including the
  inline-SVG DAG, currently hardcoded light) move to CSS custom properties, and the
  chart re-themes on toggle. The TUI's analog: an adaptive palette that reads the
  terminal's background (light vs dark) instead of fixed ANSI-256 codes.
- **The TUI is visually finished.** Lifecycle-colored cards carry an inline progress
  bar and phase count; the detail panel gains per-phase progress and task-kind markers;
  the graph columns get lifecycle color and a clearer header; the detail compose math is
  fixed so borders don't break.
- **`serve` exposes more.** A visible **health banner** surfaces manifest diagnostics
  (cycles, dangling edges) on the web. **Task-kind markers** (verify / apply / confirm)
  annotate checklist items in both surfaces. The web overview shows a **cross-change
  roll-up** (overall done/total and %). Board / Graph / Document are **deep-linkable**
  via hash routes.

### Non-goals

- **No reintroduction of a vendored interactive canvas** (pan / zoom / fit) or any new
  build-time toolchain — the realigned static, document-first design holds. The added
  web interactivity is lightweight: CSS columns for the board, anchor links and
  CSS/`:target`-driven highlighting on the static SVG, and a CSS-variable theme.
- **No network I/O in the binary.** The determinism boundary is unchanged; only the
  rendered page fetches its pinned-CDN presentation layer at view time.
- **No new data files.** Feeds stay inlined; the graph feed stays pure (nodes+edges
  only) per `visualizer-detail-feed`.
- No task-level drill-down in the graph; nodes remain whole changes.

## Capabilities

### New Capabilities
<!-- None. All work extends existing capabilities. -->

### Modified Capabilities
- `web-interaction`: add a board view, a dedicated graph view, system-synced theming,
  relationships beside the checklist, a diagnostics health banner, task-kind markers, a
  cross-change roll-up, and deep-linkable views.
- `tui-interaction`: adaptive (system-aware) palette, lifecycle-styled cards with inline
  progress, relationships beside the checklist with per-phase progress and task-kind
  markers in the detail panel.
- `visualizer-detail-feed`: carry each task item's kind (verify / apply / confirm) so
  both surfaces can mark items without re-parsing.

## Impact

- **Code**: `internal/web/web.go` and `internal/web/assets/page.html.tmpl` (the bulk —
  view switcher, board, themed CSS + toggle, two-column document, diagnostics banner,
  class-based themeable SVG, kind markers); `internal/tui/model.go` (adaptive styles,
  richer cards, detail layout, graph polish); `internal/detail/detail.go` (add `Kind`);
  `internal/cli/root.go` (`runServe` passes diagnostics + detail into `web.Render`,
  which currently discards diagnostics). Tests: extend `TestWebRuntimeIsPinnedCDN`
  scope and add web/tui/detail assertions.
- **Prerequisite / ordering**: this change extends the *realigned* `web-interaction`
  baseline. `realign-web-visualizer` (tasks complete) should archive first so the
  web-interaction spec reflects the static-CDN design before these additions layer on;
  see `design.md`.
- **Determinism guard** (`TestNoNetworkImportsInBinary`) and the **pinned-CDN guard**
  remain green — no new binary imports, no un-pinned runtime fetches.
- No manifest, lockfile, or CLI-verb-surface changes.
