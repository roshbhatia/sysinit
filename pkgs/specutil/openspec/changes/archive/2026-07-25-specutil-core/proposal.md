## Why

Spec-driven work authored in OpenSpec has to be re-keyed by hand (or by ad-hoc AI prompting) into RFCs/design docs in Notion and tickets in Linear, and there is no way to see the workstreams and the dependencies between them at a glance. We want a deterministic, framework-agnostic tool that projects OpenSpec artifacts into other artifact shapes and visualizations, while delegating the inherently non-deterministic remote writes to an AI agent through a single, non-duplicated integration path.

## What Changes

- Introduce `specutil`, a Go CLI that parses OpenSpec change artifacts into a normalized intermediate representation (IR) and projects that IR into other artifacts and views.
- **Determinism boundary (core invariant):** everything deterministic lives in the binary (pure, no network); everything non-deterministic (remote writes, drift reconciliation, judgment) is delegated to an AI agent via shipped skills that compose deterministic CLI verbs and call the agent's existing Linear/Notion MCP tools. The binary never makes network calls and never grows a native API client.
- `render --as rfc|design|tickets`: project the IR into target markdown via a declarative semantic mapping plus Go `text/template`s (embedded, user-overridable).
- `plan --target linear|notion`: emit a deterministic `plan.json` of create/update/orphan operations; `diff`: compare IR against the per-change lockfile; `lock get|set`: CLI-managed identity map between local content hashes and external IDs.
- `graph --as json|mermaid|dot`: project the cross-change dependency DAG (sourced from a repo-level `specutil.yaml` manifest, optionally seeded by shared-capability inference).
- `tui`: a bubbletea + bubblezone workstream kanban and a layered dependency graph.
- `serve`: a lightweight static web site rendering the dependency DAG as inline SVG, with its presentation layer (CSS framework, charting library) loaded from a version-pinned, SRI-protected CDN at view time while the binary stays network-free.
- Ship `sync-to-linear` and `sync-to-notion` skills in-repo that orchestrate confirm → MCP write → `lock set`, with a `--auto` escape hatch.

### Non-goals

- Native Linear/Notion (or any provider) API clients inside the binary — the agent's MCP layer owns all network I/O and auth.
- Supporting non-OpenSpec spec frameworks in v1. The architecture stays provider-agnostic (markdown-section parsing behind a provider port), but only the OpenSpec adapter ships.
- Real-time or bidirectional live sync. Sync is an explicit, agent-driven, plan/apply operation.
- Interactive task-level graph drill-down or pan/zoom in the browser; v1 is a static document with an inline-SVG workstream dependency graph.
- Mutating OpenSpec source artifacts to carry external IDs or dependency edges (no inline `[ABC-123]` annotations; no colonizing `.openspec.yaml`).

## Capabilities

### New Capabilities
- `cli-foundation`: Go module, build/dev tooling, the cobra root command, the embedded-template/asset layer, and the enforced determinism boundary (no network in the binary).
- `spec-ingestion`: the provider port, the OpenSpec adapter, the normalized IR, and lenient goldmark-based markdown parsing with loud warnings on malformed sections.
- `artifact-rendering`: the `render` verb, the declarative semantic-mapping layer, and the embedded/overridable RFC, design-doc, and tickets templates.
- `dependency-graph`: the repo-level `specutil.yaml` manifest, shared-capability inference (`--suggest`), and the `graph` verb projecting json/mermaid/dot.
- `sync-planning`: the `plan`, `diff`, and `lock` verbs; the per-change `specutil.lock.yaml`; and the stable content-hash identity strategy enabling create/update/orphan diffing.
- `integration-skills`: the in-repo `sync-to-linear` and `sync-to-notion` skills that orchestrate the deterministic verbs and the agent's MCP writes with confirmation and `--auto`.
- `tui-visualizer`: the `tui` verb — a workstream-lifecycle kanban (bubblezone mouse zones) and a layered-by-depth dependency graph view.
- `web-visualizer`: the `serve` verb — a static site consuming `graph.json` and rendering the DAG as inline SVG, with the presentation layer loaded from a pinned, SRI-protected CDN and the binary performing no network I/O.

### Modified Capabilities
<!-- None. This is a greenfield repository. -->

## Impact

- **New code:** a new Go module `github.com/roshbhatia/specutil` with `cmd/specutil` and `internal/{ir,provider,render,graph,plan,lock,tui,web}` packages.
- **Dependencies:** goldmark (parsing), cobra (CLI), bubbletea + bubblezone + lipgloss (TUI), and `embed` for templates/assets. A Nix flake / dev shell provides the toolchain.
- **New durable artifacts in consuming repos:** `openspec/specutil.yaml` (cross-change dependency DAG), per-change `openspec/changes/<name>/specutil.lock.yaml` (identity map), and a derived `graph.json`.
- **Skills:** `skills/sync-to-linear/SKILL.md` and `skills/sync-to-notion/SKILL.md` shipped in-repo, installed by home-manager downstream.
- **Impactful/irreversible actions** (each becomes a human-verification checkpoint in tasks.md, and is gated behind the agent's confirmation flow, never the binary): remote writes to Linear/Notion via MCP, `git push`, and any `lock set` write-back. The binary itself performs no impactful external action by construction.
- **Gating signal:** the determinism boundary is the kill switch — because the binary is pure, any failure is local and reversible; the only externally-visible mutations happen in the agent-driven sync skills, which default to per-operation confirmation.
