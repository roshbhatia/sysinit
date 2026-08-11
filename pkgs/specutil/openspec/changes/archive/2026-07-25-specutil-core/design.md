## Context

`specutil` is a greenfield Go CLI. It reads OpenSpec change artifacts (`proposal.md`, `specs/**/*.md`, `design.md`, `tasks.md` under `openspec/changes/<name>/`) and projects them into other artifacts (RFCs, design docs, ticket sets) and visualizations (TUI, static web). The OpenSpec artifact shapes are heading-driven markdown: proposals use `## Why / ## What Changes / ## Capabilities / ## Impact`; specs use `## ADDED|MODIFIED|REMOVED|RENAMED Requirements` with `### Requirement:` and `#### Scenario:` blocks; tasks use `## N. Phase` headings with `- [ ] N.M` checkboxes.

The defining constraint is a **determinism boundary**: the binary is pure and never touches the network; the agent (via MCP) is the only thing that performs remote writes. This exists because remote sync is inherently stateful and non-deterministic (auth, rate limits, drift, conflict resolution), and the user already has Linear/Notion MCP tooling. Reimplementing that as a native client would create a second, divergent integration path — explicitly rejected.

No prior art exists in this repo (initial commit). Downstream, the user's dotfiles repo installs skills via home-manager and uses a forked `rosh-spec-driven` OpenSpec schema; this repo uses the stock `spec-driven` schema and ships its own skills to be installed downstream.

## Goals / Non-Goals

**Goals:**
- A normalized IR that is the single source for every projection ("IR → projection").
- Deterministic, pure, testable rendering and planning with zero network I/O in the binary.
- Exactly one integration path for remote systems: deterministic CLI verbs composed by shipped skills that drive the agent's MCP tools.
- Provider-agnostic ingestion (markdown-section parsing behind a port) shipping only an OpenSpec adapter in v1.
- Progressive, independently shippable vertical slices.

**Non-Goals:**
- Native API clients, auth handling, or any network I/O in the binary.
- Non-OpenSpec providers, bidirectional/live sync, and browser task-level drill-down in v1.
- Mutating OpenSpec source artifacts to carry specutil state.

## Decisions

**D1 — Determinism boundary: binary = plan, skill = apply.** The binary renders artifacts and emits a `plan.json` of intended remote operations; shipped skills drive the agent to apply them via MCP, then record results through `lock set`. *Alternative rejected:* native Linear/Notion clients in the binary — duplicates the agent's MCP integration, drags auth/rate-limit/state complexity into a "pure" tool, and creates two paths that drift.

**D2 — IR is a hybrid model.** Each section is parsed into structured fields **and** retains its raw markdown block. *Alternative rejected:* fully-structured-only — lossy for round-trip and forces the parser to understand prose it only needs to pass through; raw-only — pushes section logic into every renderer.

**D3 — Identity via sidecar lockfile, not inline annotations.** A per-change `openspec/changes/<name>/specutil.lock.yaml` maps stable content hashes → external IDs, managed only through `lock get|set`. *Alternative rejected:* inline `[ABC-123]` in tasks.md / frontmatter — mutates and pollutes OpenSpec source and couples drift to artifact edits.

**D4 — Dependencies from a repo-level manifest, optionally inferred.** `openspec/specutil.yaml` is the source of truth for the cross-change DAG; `graph --suggest` proposes edges from shared capabilities but never writes them silently. *Alternative rejected:* storing deps in OpenSpec's `.openspec.yaml` — couples to OpenSpec internals and breaks framework-agnosticism; inference-only — approximate and noisy.

**D5 — Small CLI primitives, no fat `sync` verb in the binary.** Verbs are `render`, `plan`, `diff`, `lock`, `graph`, `tui`, `serve`. *Alternative rejected:* a `sync` verb — would either make network calls (violates D1) or be a dry orchestrator redundant with the skill. Orchestration lives in the skill.

**D6 — Lenient parser with loud warnings.** goldmark AST parsing accepts slightly-malformed sections (e.g., wrong hashtag depth) and emits warnings rather than silently dropping content. *Alternative rejected:* strictly mirroring OpenSpec's TS parser — drift risk exists either way; lenient-with-warnings is friendlier and surfaces authoring mistakes the TS parser hides.

**D7 — Two-layer rendering: semantic mapping + presentational template.** A declarative mapping (IR section → target section) feeds a Go `text/template`. RFC/design target skeletons mirror the user's `writing-doc-rfc` (Rust RFC) and `writing-doc-design` (KEP) skills. *Alternative rejected:* mapping baked into templates — couples "what feeds what" to layout and blocks retargeting.

**D8 — TUI imports the IR package directly; web consumes `graph.json`.** The determinism boundary governs *integrations*, not in-process reads; the browser cannot link Go, so the file boundary is real only there. *Alternative rejected:* TUI shelling out to the binary — dogmatic, slower, no benefit.

**D9 — Static document with a binary-rendered inline-SVG graph; presentation layer from a pinned CDN.** `serve` emits a static site (single HTML document) whose cross-change DAG is a deterministic inline SVG emitted by the binary, while styling and the per-phase progress chart load from a version-pinned, SRI-protected CDN (`crossorigin` + `onerror` fallback) at view time. The binary performs no network I/O and adds no build-time toolchain. *Alternatives rejected:* a vendored, fully-offline interactive canvas (Cytoscape/Mermaid bundles inlined) — heavier, harder to read, and the readability-first redesign dropped pan/zoom/drill-down; rendering the DAG via a client-side library — needless when the layout is deterministic and computable in Go.

**D10 — cobra + goldmark + bubbletea/bubblezone/lipgloss.** Conventional, stable choices matching the ecosystem and the bubblezone requirement for mouse zones.

## Risks / Trade-offs

- [Stable task identity] → A task's text and number both change over time, so a naive content hash orphans its external ID on any edit. **Mitigation:** hash on a normalized, position-independent key (phase + normalized text) and support fuzzy re-match during `diff`; treated as an Open Question until validated against real edit patterns.
- [Parser drift from OpenSpec] → A Go reimplementation can diverge from OpenSpec's TS parser. **Mitigation:** lenient parsing + warnings (D6) and golden-file tests against real fixtures; the provider port isolates parsing so it can be replaced.
- [Notion is blocks, not markdown] → Rendering markdown locally assumes the agent can create Notion content from markdown. **Mitigation:** confirm `notion-create-pages` accepts markdown; if not, the `sync-to-notion` skill carries the block-conversion guidance (still agent-side, no binary change).
- [Scope] → Eight capabilities is large for one change. **Mitigation:** strict slice ordering (below) so each lands and is verifiable independently.
- [Inline-SVG graph scale] → A hand-laid inline-SVG DAG is workstream-level only and would crowd past a few dozen nodes. **Mitigation:** v1 is workstream-level (tens of nodes), laid out in deterministic depth-ordered columns; task-level drill-down is an explicit non-goal (D9).
- [CDN presentation layer] → The page's styling/chart load from a CDN, so it is not fully offline and a CDN swap is a supply-chain surface. **Mitigation:** versions are pinned with SRI hashes + `crossorigin`, an `onerror` fallback degrades loudly to an offline notice, and the inlined content (text, SVG DAG, data feeds) still renders; the binary itself stays network-free (D9).

## Migration Plan

Greenfield — no migration. Rollout is the slice sequence; each slice gates the next:

1. **cli-foundation + spec-ingestion** — module, Nix dev shell, cobra root, provider port, IR, parser. Gate: `nix develop` builds; `go test ./...` green; parsing a real fixture round-trips.
2. **artifact-rendering** — `render` + mapping + templates. Gate: golden-file render tests pass.
3. **dependency-graph** — `specutil.yaml`, `graph`, `--suggest`. Gate: graph projections match fixtures.
4. **sync-planning** — `plan`, `diff`, `lock`, hashing. Gate: plan/diff golden tests; lock round-trips.
5. **integration-skills** — `sync-to-linear` / `sync-to-notion`. Gate: skill dry-run against a sample plan with confirmations; no binary network calls.
6. **tui-visualizer** — `tui`. Gate: renders against a fixture repo.
7. **web-visualizer** — `serve`. Gate: static site renders the DAG as inline SVG with the binary performing no network I/O; presentation layer loads from a pinned, SRI-protected CDN.

Each impactful action (remote MCP writes, `git push`, `lock set` write-back) is preceded by a verification task and followed by a confirmation task in tasks.md. The binary performs no impactful external action by construction, so the kill switch is simply "don't run the sync skill."

## Open Questions

- **Stable task-identity hashing.** What normalization makes a task's hash survive renumbering and minor text edits without colliding across distinct tasks? Resolve in the sync-planning slice with fixtures of real edit histories.
- **Notion markdown ingestion.** Does `notion-create-pages` accept markdown directly, or must the skill convert to blocks? Confirm before finalizing the `sync-to-notion` skill.
- **Semantic-mapping format surface.** Start with a minimal YAML mapping (section→section); revisit whether transforms (split/merge/invert) need a richer DSL once real RFC/design renders exist.
- **Should specutil ship its own OpenSpec authoring schema** (with a `## Dependencies` block) to seed the manifest, or stay purely a consumer? Lean consumer-first; revisit after the graph slice.
