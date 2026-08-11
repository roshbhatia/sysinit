## 1. Foundation (cli-foundation + spec-ingestion)

- [x] 1.1 Initialize Go module `github.com/roshbhatia/specutil` with `go.mod` (Go 1.22+) and a `cmd/specutil` entrypoint
- [x] 1.2 Add a Nix flake + dev shell pinning the Go toolchain, goldmark, cobra, bubbletea/bubblezone/lipgloss
- [x] 1.3 Verify: `nix develop -c go build ./...` succeeds in the dev shell
- [x] 1.4 Scaffold the cobra root command with stub subcommands `render`, `plan`, `diff`, `lock`, `graph`, `tui`, `serve` (no `sync` verb)
- [x] 1.5 Add a determinism guard: a test/lint that fails if any binary code path imports a network package
- [x] 1.6 Define the IR types in `internal/ir` (hybrid structured + raw per section; change/proposal/specs/design/tasks; graph edges change→capability→requirement→task)
- [x] 1.7 Define the provider port in `internal/provider` and implement the OpenSpec adapter that discovers `openspec/changes/<name>/` and loads artifacts
- [x] 1.8 Implement lenient goldmark parsing with loud warnings (recover wrong-depth scenarios; classify task kind verify/apply/confirm; tag delta ops)
- [x] 1.9 Add golden-file fixtures from a real OpenSpec change and tests asserting round-trip of structured + raw views
- [x] 1.10 Confirm: `go test ./...` green; parsing a fixture yields the expected IR and emits warnings for malformed input

## 2. Rendering (artifact-rendering)

- [x] 2.1 Define the declarative semantic-mapping representation (IR section → target section) in `internal/render`
- [x] 2.2 Add embedded templates via `embed.FS` for `rfc`, `design`, `tickets`, mirroring the canonical RFC and design-doc skeletons; support override directory with loud fallback
- [x] 2.3 Implement the `render --as rfc|design|tickets` verb (deterministic byte output; unknown target rejected; absent source section warned)
- [x] 2.4 Confirm: golden-file render tests pass and re-running render produces byte-identical output

## 3. Graph (dependency-graph)

- [x] 3.1 Define and load the repo-level `openspec/specutil.yaml` manifest (edge list); detect dangling references and cycles
- [x] 3.2 Implement `graph --as json|mermaid|dot` (json is the canonical, byte-stable feed)
- [x] 3.3 Implement `graph --suggest` shared-capability inference that reports candidate edges without mutating the manifest
- [x] 3.4 Confirm: graph projections match fixtures; suggest leaves `specutil.yaml` unchanged

## 4. Sync planning (sync-planning)

- [x] 4.1 Implement the stable content-hash identity (normalized, position-independent; survives renumber; no collisions) and resolve the hashing Open Question against edit-history fixtures
- [x] 4.2 Implement the per-change `specutil.lock.yaml` and `lock get|set` (no external IDs written to source artifacts)
- [x] 4.3 Implement `plan --target linear|notion` emitting create/update/orphan `plan.json` with no network I/O
- [x] 4.4 Implement `diff` (IR vs lock) reporting new/changed/orphaned with fuzzy re-match
- [x] 4.5 Confirm: plan/diff golden tests pass; lock round-trips; all four verbs run offline

## 5. Integration skills (integration-skills)

- [x] 5.1 Confirm whether `notion-create-pages` accepts markdown directly; record the answer and adjust the notion skill's block-conversion guidance accordingly
- [x] 5.2 Author `skills/sync-to-linear/SKILL.md`: plan → review → MCP write → `lock set`; confirmation default + `--auto`
- [x] 5.3 Author `skills/sync-to-notion/SKILL.md` following the same flow
- [x] 5.4 Verify: dry-run each skill against a sample `plan.json` with confirmations; assert the binary makes no network calls and write-back goes through `lock set`
- [ ] 5.5 Apply: exercise `sync-to-linear` end-to-end against a real Linear target via MCP (user-confirmed; impactful — remote writes)
- [ ] 5.6 Confirm: created Linear issues match the plan and their IDs are recorded in the lockfile

> Archived with 5.5 and 5.6 not performed. Both need a real Linear workspace and
> a user-confirmed remote write, which never happened. The skill was validated
> against a sample plan by 5.4 only.

## 6. TUI (tui-visualizer)

> The `tui` verb shipped and was later removed; the `tui-visualizer` capability
> no longer exists. The tasks below record what was built, not what the tool
> does today.

- [x] 6.1 Implement the bubbletea + bubblezone workstream kanban (lifecycle columns; mouse zones; empty-repo guidance)
- [x] 6.2 Implement the layered-by-depth dependency graph view (cycle surfaced, not looped)
- [x] 6.3 Confirm: `specutil tui` renders correctly against a fixture repo and an empty repo

## 7. Web (web-visualizer)

- [x] 7.1 Implement `serve`: static single-file site rendering the DAG from `graph.json` as binary-emitted inline SVG; presentation layer (CSS framework + per-phase progress chart) loaded from a version-pinned, SRI-protected CDN; binary performs no network I/O; graceful empty state
- [x] 7.2 Confirm: site renders the dependency graph as inline SVG with the binary making no network calls, the CDN runtime is pinned + SRI + `crossorigin` + `onerror`, and the `graph.json` schema is renderer-independent

## 8. Rollout

- [x] 8.1 Verify: `nix develop -c go build ./...` and `go test ./...` green; determinism guard passes; `git diff` reviewed
- [x] 8.2 Apply: push the branch and open a PR (impactful — `git push`; never push to `main`)
- [ ] 8.3 Confirm: CI green and PR reflects the intended diff

> Archived with 8.3 not performed. The work landed on `main` directly rather
> than through a PR, so there was no PR diff to confirm.
