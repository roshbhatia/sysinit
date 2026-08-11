# Agent context for specutil

This file is for AI coding agents (Claude, Codex, Cursor, etc.) working in
this repository. Read it before making any changes.

---

## What this project is

`specutil` is a **CLI** — a pure, local tool. It reads spec-framework change
artifacts (OpenSpec, BMAD, plain `plan.md`) from the local filesystem and
projects them into RFCs, design docs, sync plans, dependency graphs, and
visualizations.

**The binary never makes network calls.** Remote writes (Linear, Notion, GitHub
Issues) are handled by AI skills in `skills/` — not by the binary itself. This
is the core architectural invariant. Do not break it.

---

## Repository map

```
cmd/specutil/         entry point (thin: parse flags, call cli.NewRootCmd)
internal/
  cli/                cobra command tree; all verb wiring lives here
  ir/                 normalized intermediate representation (IR)
  provider/           input providers: openspec, bmad, plan, stdin, script
  registry/           provider and target registration; wraps providers with extract
  extract/            schema-declared marker/field grammar (composable, config-driven)
  check/              rubric rules and presets for the check verb
  ident/              content-addressed task handles (identity, hash, similarity)
  review/             human verdict on a change: record, drift, agent brief
  vcs/                local git working-tree diff, parsed into files and hunks
  export/             IR → tracker vocabulary (the naming boundary)
  render/             IR → RFC / design / tickets Markdown
  syncplan/           IR → create/update/orphan JSON plan
  graph/              dependency DAG (mermaid, dot, json)
  web/                HTML dashboard (embedded assets, annotation surface)
  detail/             per-change detail view
skills/               AI skills for remote writes (one dir per target)
examples/             working examples (bmad-project, getting-started, plan-md)
assets/               logo SVG
hack/                 shell scripts (shfmt-formatted)
```

---

## Core invariant

```
┌─────────────────────────────────────┐
│  specutil binary (this repo)        │
│  - reads local files only           │
│  - pure: same input → same output   │
│  - no network, no auth, no secrets  │
└──────────────┬──────────────────────┘
               │ emits plan JSON / rendered Markdown
               ▼
┌─────────────────────────────────────┐
│  AI skill (skills/sync-to-*/...)    │
│  - reads the plan                   │
│  - drives MCP tools for API calls   │
│  - calls `specutil lock set` after  │
└─────────────────────────────────────┘
```

Any code that makes a network call, reads credentials, or writes to an external
service belongs in a skill, not in the binary.

---

## The naming boundary

`internal/export` is where spec-framework convention stops. Anything that leaves
the repository — a Linear issue, a Notion page, a GitHub issue — goes through it.

It strips: task identifiers (`1.1`), phase numbers (`## 2.`), sibling keys
(`1a`), the verify/apply/confirm keyword (it becomes a label), and spec delta
keywords (`ADDED Requirements`). It translates requirements and scenarios into
Given/When/Then acceptance criteria.

Ordering that the numbering used to carry moves to the target's own primitives:
`Ticket.Position` for sort order, `Ticket.Milestone` for the stage, and blocking
relations between consecutive stages (drawn by the skill).

If you add a field that reaches a tracker, route it through `export`. If you find
yourself formatting a title in a skill, the formatting belongs here instead.

---

## Schema-specific conventions are composable, not assumed

specutil ships plain OpenSpec support and nothing more by default. A spec
framework that layers extra convention on top of markdown (a scenario's
polarity, a phase's shape, an inline task-dependency field) declares that
convention in `openspec/specutil.yaml` under `extract:`, or gets it for free
when its own config names a schema specutil recognizes (`internal/extract`'s
built-in presets, e.g. `rosh-spec-driven`). Nothing in `parse`, the providers,
`export`, `graph`, or `web` hard-codes a specific framework's marker names.

Adding support for a new convention means adding an `extract.Marker` or
`extract.Field` declaration (or a new preset), never a branch keyed on a schema
name in a consuming package. If you catch yourself writing
`if schema == "some-framework"` anywhere outside `internal/extract` or
`internal/check`, stop: that knowledge belongs in a preset instead.

The same rule governs `internal/check`. A rubric rule is generic and takes
parameters (`required-sections` with a section list, `phase-marker-required`
with a marker name); the framework-specific values live only in a preset in
`internal/check/presets.go`.

## The review loop is the only inbound path

Every other package projects what the author wrote outward. `internal/review` is
the one path that goes the other way: a person annotates the change in the
browser page, exports a JSON document, and `specutil review ingest` folds it
into `openspec/changes/<name>/specutil.review.yaml`.

Two rules keep it inside the invariant.

**Reading git is a local read; talking to a forge is not.** `internal/vcs` runs
the local `git` binary to collect a working-tree diff, the same class of
operation as reading a file. It must never fetch, push, clone, or hit a forge
API. A pull-request URL does not belong here: that is a network read, and it
belongs in a skill.

**The page exports; it never posts.** It has no `fetch`, no `WebSocket`, no
`<form>`, and no server behind it. Feedback leaves as a document the user copies
or downloads. `internal/guard`'s `TestWebFeedbackIsExportedNotPosted` fails the
build if that changes, because a listener would mean network I/O in the binary.

**Staleness is a hash, never a timestamp.** A review record fingerprints the
artifacts it describes. An edit reports the decision stale rather than letting
it stand. Do not add a recorded time to the record: it would make two runs over
the same repository disagree and would break resume-from-checkout.

Handles come from `internal/ident`, which is the single definition of identity
(normalized, edit-tolerant), content hash (exact), and similarity (token
Jaccard). `syncplan` delegates to it, and `vcs` builds a hunk's handle from its
changed lines alone so an edit elsewhere in the file does not orphan a comment.
If you need to name something in a new consumer, call `ident`, do not re-derive
one.

### Adding a check rule

1. Register it in `internal/check/rules.go` with an ID, a one-line doc, and
   parameters. The doc shows up in `specutil check --list-rules`
2. Read only stated facts (a heading, a declared marker, a bullet ordering).
   A rule that infers intent from prose is not reproducible and does not belong
3. Reference it from a preset if a framework needs it
4. Test the pass case and the fail case in `internal/check/check_test.go`

---

## Making changes

### Adding an input provider

1. Implement `provider.Provider` in `internal/provider/<name>/<name>.go`
2. Register in `internal/registry/registry.go`
3. Add auto-detection logic to `detect()` if the provider can be inferred from
   repo layout
4. Unit-test the section-mapping: absent sections must emit warnings, not errors
   (tolerant-parse contract)

### Adding a sync target

1. Write a skill at `skills/sync-to-<name>/SKILL.md` following the pattern of
   `skills/sync-to-linear/SKILL.md`
2. Map change/phase/task onto that target's own primitives; state the mapping in
   a table in the skill
3. Register the skill in `flake.nix` under `lib.skills`
4. No binary changes are needed. The plan is target-neutral: every operation
   already carries `title`, `milestone`, `position`, `labels`, and `body`

### Adding a render format

1. Add the format to `render/mapping.go`
2. Implement the template in `render/templates/`. Read from `.Export` for
   anything a reader outside the repo sees; `.Change` is the raw IR and carries
   source numbering
3. Integration-test via `internal/cli/cli_test.go` (see `TestRenderRFC` pattern)

---

## Testing

```bash
go test ./...              # all tests
go test ./internal/cli/... # CLI integration tests (call cobra directly, no exec)
go test -race ./...        # with race detector (required before merging)
```

Integration tests in `internal/cli/cli_test.go` call `cli.NewRootCmd()` and
`Execute()` directly. Use `examplesDir()` to resolve fixture paths relative to
the repo root. Do not use `os.Exec` or shell out to the binary in tests.

Fixture data lives in `examples/`. Use `setupMinimalOpenspec()` for tests that
need a bare-minimum OpenSpec tree without depending on a specific example.

---

## Style rules

- **Conventional commits, title-only.** `feat`, `fix`, `chore`, `docs`, `test`.
  No body required.
- **One concern per PR.** Bug fix ≠ cleanup.
- **No comments** unless the WHY is non-obvious (hidden constraint, workaround,
  subtle invariant). Never restate what the code says.
- **No network I/O in the binary.** Not even `http.Get`. Remote calls belong in
  skills.
- Shell scripts in `hack/` use `set -euo pipefail` and are formatted with
  `shfmt -i 2 -ci -sr -s`.
- Nix files are formatted with `nixfmt-rfc-style` (`nix fmt`).

---

## What not to do

- Do not add a `sync` verb. Sync lives in skills.
- Do not write source numbering into anything a tracker or a reader outside the
  repository sees. Route it through `internal/export` instead.
- Do not add global state, init functions that do I/O, or package-level HTTP
  clients.
- Do not modify `flake.nix` or `flake.lock` without understanding the overlay
  structure in `overlays/`.
- Do not add dependencies without discussion — the binary surface is
  intentionally small.
- Do not run `--no-verify` or bypass pre-commit hooks.

---

## Running locally

```bash
nix develop              # enter dev shell (Go toolchain + tools)
go build -o specutil ./cmd/specutil
./specutil --help

# Validate the flake before touching flake.nix
nix flake check
```
