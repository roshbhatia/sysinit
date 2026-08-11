## 1. Shared model: task kind through the detail feed

- [x] 1.1 Add `Kind` to `detail.Item` in `internal/detail/detail.go`, populated from
      `ir.TaskItem.Kind`; keep the projection pure and deterministic.
- [x] 1.2 Confirm: `go test ./internal/detail/` passes and the projection stays
      byte-identical across two runs (add/extend a determinism assertion if needed).

## 2. Web: theming (system-synced light/dark)

- [x] 2.1 Move every color in `page.html.tmpl` to `:root` CSS custom properties with a
      `[data-theme="dark"]` override; default via `@media (prefers-color-scheme: dark)`.
- [x] 2.2 Add a pre-paint head script that applies `data-theme` from `localStorage` before
      the stylesheet, and an Auto/Light/Dark toggle control that cycles and persists.
- [x] 2.3 Re-style the inline-SVG DAG to use lifecycle CSS classes (no hardcoded fills) so
      it tracks the theme; re-read Chart.js colors from CSS vars and re-render on toggle.
- [x] 2.4 Confirm: page renders correctly in light and dark, with no theme flash, and
      `TestWebRuntimeIsPinnedCDN` still passes (no new un-pinned CDN deps).

## 3. Web: board and graph views + view switcher

- [x] 3.1 Add a top-level view switcher (Board / Graph / Document) with hash routes
      (`#/`, `#/graph`, `#/c/<name>`); single change still lands on its document, multi
      lands on the board.
- [x] 3.2 Implement the board: lifecycle columns of progress cards (lifecycle color +
      meter + done/total + phase count), card click navigates to the document; show the
      cross-change roll-up (overall done/total) beside the lifecycle tally.
- [x] 3.3 Promote the inline-SVG DAG to a full-width graph view; stamp nodes with lifecycle
      classes, wrap each in `<a href="#/c/<name>">`, and add CSS-only incident
      emphasis on hover/`:target`.
- [x] 3.4 Confirm: board groups by lifecycle, graph nodes navigate and are lifecycle-colored,
      and all three views are reachable by hash route.

## 4. Web: document with relationships beside the checklist + diagnostics + kind markers

- [x] 4.1 Lay the per-change document out two-column on wide viewports (checklist main; a
      sticky rail with lifecycle badge, progress meter, per-phase chart, and depends-on/
      blocks chips), collapsing to one column when narrow.
- [x] 4.2 Mark verify/apply/confirm items in the checklist using the new `Kind` field.
- [x] 4.3 Thread `graph.Build` diagnostics into `web.Render` (currently discarded in
      `runServe`) and render a visible health banner when cycles/dangling exist.
- [x] 4.4 Confirm: relationships render beside the checklist (and stack when narrow), kind
      markers appear, and a seeded cycle/dangling edge shows the banner.

## 5. TUI: parity and visual polish

- [x] 5.1 Replace hardcoded ANSI-256 colors in `internal/tui/model.go` with
      `lipgloss.AdaptiveColor` (light/dark variants) for lifecycle, selection, neighbor,
      progress, and done states.
- [x] 5.2 Enrich cards: lifecycle-derived color + inline progress bar + done/total (and
      phase count), keeping the narrow-terminal fallback readable.
- [x] 5.3 Rework the detail panel: relationships beside the checklist, per-phase progress,
      and task-kind markers; fix `composeDetail` width math so borders don't break.
- [x] 5.4 Polish the graph view: lifecycle-colored nodes and clearer column headers; keep
      focus+context neighbor highlighting and the diagnostics lines.
- [x] 5.5 Confirm: `go test ./internal/tui/` passes (covers kanban/list/graph/detail/empty
      render paths against the fixture); AdaptiveColor resolves the light/dark split at
      runtime from the terminal background. (Interactive light/dark confirmation needs a
      real TTY, unavailable in this sandbox.)

## 6. Rollout

- [x] 6.1 Verify: `gofmt -l internal/` clean, `go vet ./...`, `go test ./...`, and the
      determinism guard (`TestNoNetworkImportsInBinary`) all green; `nix build` succeeds.
- [x] 6.2 Confirm: archive `realign-web-visualizer` first (so `web-interaction` reflects the
      static-CDN baseline), then `git diff` reviewed and the change is ready to apply.
