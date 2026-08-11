<div align="center">
  <img src="assets/logo.svg" alt="specutil mascot" width="96"/>
  <h1>specutil</h1>
  <p>Bridge your local spec workflow to the rest of your stack.</p>
</div>

Write specs in OpenSpec, BMAD, or a plain `plan.md`. specutil renders them as shareable docs, syncs tasks to Linear, Notion, or GitHub Issues, and shows how your changes depend on each other — all from your repo, no manual copy-paste.

```
specutil [render|plan|diff|lock|graph|check|review|web] [--from <provider>] [flags]
```

## What it does

```
Input providers (--from)           Core IR              Output
────────────────────────           ────────             ──────
openspec (default)   ──────────▶                ──▶ render  → RFC / design doc / tickets
bmad stories/*.md    ──────────▶  ir.Change     ──▶ plan    → create/update/orphan JSON
plan.md convention   ──────────▶                ──▶ diff    → lockfile delta
stdin / pipe         ──────────▶                ──▶ lock    → identity map
script adapters      ──────────▶                ──▶ graph   → DAG (json/mermaid/dot)
                                                ──▶ check   → rubric violations (CI gate)
                                                ──▶ review  → human verdict + drift since it
                                                ──▶ web     → HTML dashboard (annotatable)
```

The binary reads local artifacts and emits structured output — no network I/O. Remote writes (auth, drift reconciliation, actual Linear/Notion/GitHub API calls) are handled by a shipped AI skill that drives the agent's MCP tools.

## Installation

### Nix (recommended)

```bash
# Run without installing
nix run github:roshbhatia/specutil -- --help

# Install via nix profile
nix profile install github:roshbhatia/specutil
```

### go install

Requires Go 1.24+.

```bash
go install github.com/roshbhatia/specutil/cmd/specutil@latest
```

### Binary releases

Pre-built binaries for macOS and Linux (amd64 + arm64) are available on the
[Releases](https://github.com/roshbhatia/specutil/releases) page. Download
the archive for your platform and put `specutil` on your `$PATH`.

```bash
# Example: macOS arm64
curl -L https://github.com/roshbhatia/specutil/releases/latest/download/specutil_$(uname -s)_$(uname -m).tar.gz \
  | tar xz && mv specutil /usr/local/bin/
```

### Homebrew

A tap is in the works. Once available:

```bash
brew install roshbhatia/tap/specutil
```

### From source

```bash
git clone https://github.com/roshbhatia/specutil
cd specutil
nix develop          # enter dev shell with Go toolchain
go build -o specutil ./cmd/specutil
```

## Quickstart

```bash
# OpenSpec project (auto-detected)
specutil render --as rfc
specutil plan --target linear

# BMAD project
specutil render --from bmad stories/story-1.1.md --as tickets
specutil plan --from bmad --target github-issues

# AI-generated plan.md
specutil render --from plan plan.md --as rfc

# Pipe from any tool
./my-adapter.sh my-change | specutil render --from stdin --as design

# Script adapter (declared in openspec/specutil.yaml)
specutil render --from jira --change PROJ-123 --as rfc
```

### Input provider auto-detection

When `--from` is omitted, specutil detects the provider from the repo layout:

| Signal | Provider |
|--------|----------|
| `openspec/changes/` directory | `openspec` |
| `stories/*.md` files | `bmad` |
| `plan.md` at root | `plan` |

### plan.md convention

Any markdown file that follows this structure works with `--from plan`:

```markdown
# change-name

## Why
One paragraph explaining the motivation.

## What Changes
- capability: description

## Tasks

### Phase 1: Foundation
- [ ] 1.1 First task
- [ ] 1.2 Second task
```

### Script adapters

Declare custom providers in `openspec/specutil.yaml`:

```yaml
providers:
  - name: jira
    command: "./hack/fetch-jira.sh {change}"
  - name: confluence
    command: "./hack/fetch-confluence.sh {change}"
```

Scripts receive the `--change` value as `{change}` and emit openspec-compatible markdown to stdout.

## Commands

### `render`

Projects a change's IR into a target artifact format.

```bash
specutil render [change] --as rfc|design|tickets [--from <provider>] [-o output.md]
```

| Flag | Description |
|------|-------------|
| `--as` | Target format: `rfc`, `design`, or `tickets` (required) |
| `--from` | Input provider: `openspec`, `bmad`, `plan`, `stdin`, or a script adapter name |
| `--change` | Change name (or pass as positional arg) |
| `--templates` | Override template directory |
| `-o` | Write to file instead of stdout |

```bash
# OpenSpec repo (auto-detected)
specutil render my-feature --as rfc -o docs/rfc.md

# BMAD story file
specutil render --from bmad stories/story-1.1.md --as tickets

# AI plan file
specutil render --from plan plan.md --as design

# Stdin (pipe from any tool)
cat plan.md | specutil render --from stdin --as rfc
```

### `plan`

Emits a create/update/orphan plan for syncing to a remote target.

```bash
specutil plan [change] --target linear|notion|github-issues [--from <provider>] [-o plan.json]
```

The plan is a list of operations (`create`, `update`, `orphan`) keyed by stable content hashes, with no network calls made by the binary itself.

Every operation is ready to write: `title`, `milestone`, `position`, `labels`, and a rendered Markdown `body`. The plan also carries an `overview` body for the container the target groups tickets under — a Linear project, a GitHub milestone, or a Notion page — which holds the acceptance criteria once. The sync skills copy these fields verbatim; no re-templating required.

### Naming across the boundary

Source numbering never reaches an external tracker. `1.1`, `## 2. Rollout`, sibling keys like `1a`, and spec delta keywords like `ADDED Requirements` all stop at the export layer.

| In the repo | In Linear / Notion / GitHub |
|---|---|
| `add-auth-layer` | `Add auth layer` (the slug stays in the lockfile) |
| `## 1. Foundation` | milestone `Foundation` |
| `- [ ] 1.4 verify: tests pass` | issue `Tests pass`, label `kind:verify` |
| `#### Scenario: missing token` | `- [ ] **Missing token**` with Given/When/Then sub-bullets |
| `## ADDED Requirements` | `## Acceptance criteria` |

Requirements and scenarios become acceptance criteria a reader outside the repo can check off. Ordering that the numbering used to carry is expressed with the target's own primitives instead: `position` for sort order, `milestone` for the stage, and blocking relations between consecutive stages.

### `diff`

Compares the local IR against the per-change lockfile to show what has drifted.

```bash
specutil diff [change] --target linear
```

### `lock`

Manages the identity map between content hashes and external IDs (e.g., Linear issue IDs).

```bash
# Read an entry (exits 3 if not found)
specutil lock get <identity> --target linear --change my-feature

# Write an entry
specutil lock set <identity> <external-id> --target linear --change my-feature \
  --content-hash <hash> --title "Issue title"
```

The lockfile lives at `openspec/changes/<name>/specutil.lock.yaml` and is never written to source — only managed by `lock set`.

### `graph`

Projects the cross-change dependency DAG.

```bash
specutil graph --as json|mermaid|dot [-o graph.json]
specutil graph --suggest    # infer candidate edges without mutating the manifest
```

Dependencies come from `openspec/specutil.yaml`. Use `--suggest` to get inferred candidates from shared capabilities (does not write the file).

### `check`

Validates changes against a declared rubric and exits non-zero on violation, so
it works as a pre-commit hook or a CI gate.

```bash
specutil check                  # every change
specutil check my-change        # one change
specutil check --as json | jq   # machine-readable findings
specutil check --list-rules     # what the built-in rules are
```

Rules are generic and parameterized; the repository supplies the specifics under
`check:` in `openspec/specutil.yaml`. As with `extract:`, a recognized `schema:`
in `openspec/config.yaml` selects a matching preset automatically, and a
repository with neither declared is not checked.

```yaml
# openspec/specutil.yaml
check:
  preset: rosh-spec-driven
  disable: [no-em-dash]          # drop one rule
  rules:
    - id: bolded-bullet-lead     # retune another
      severity: warn
      allow: [WHEN, THEN, BREAKING]
```

Built-in rules:

| Rule | Enforces |
|---|---|
| `required-sections` | an artifact contains each named heading |
| `paired-bullet` | every lead bullet is followed by its counterpart |
| `scenario-marker-coverage` | every requirement has a scenario declaring marker=value |
| `phase-marker-required` | every phase declares a marker |
| `phase-marker-conditional` | a phase with one marker value declares its dependents |
| `phase-task-pattern` | every phase contains a task matching a pattern |
| `task-deps-resolve` | every declared task dependency names a real sibling |
| `task-deps-acyclic` | declared task dependencies do not form a cycle |
| `no-em-dash` | no artifact contains an em-dash |
| `bolded-bullet-lead` | bullets do not open with a disallowed bolded term |
| `review-decision-current` | a recorded review decision exists and still describes the artifacts |

Every rule reads only what the author stated: a heading that is present, a
marker that is declared, a bullet that follows another. None infers intent from
prose, so two runs over the same input always agree.

Exit codes: `0` passed (warnings may still print), `1` at least one
error-severity violation.

### `review`

Carries a human verdict back to the agent that wrote the change. `specutil web`
collects the annotations; this folds them in and reports what moved since.

```bash
specutil review show [change]         # the standing verdict, comments, and drift
specutil review diff [change]         # the working-tree diff since the review
specutil review ingest [file|-]       # fold in an export from the web page
specutil review set <change> --decision approved
```

The record lives at `openspec/changes/<name>/specutil.review.yaml`. It stores
the reviewer's decision, their note, per-task comments, and a fingerprint of
every artifact as it read at review time.

```bash
specutil web                              # annotate, pick a decision, press Copy
pbpaste | specutil review ingest          # record it, print the brief
specutil review show my-change            # after revising: what drifted
```

The brief is ordered by what blocks work: requested removals, then comments on
tasks, then comments on code, then tasks that changed after the reviewer read
them.

`review diff` shows the code, not just the plan. Its base defaults to the commit
recorded when the decision was taken, so with no flags it answers "what did the
agent do after I looked at this". It reads the local git working tree by running
git, including files git does not track yet; it contacts no remote and reads no
credentials. Outside a git working tree it reports an empty diff with the reason.

```bash
specutil review diff my-change              # since the review
specutil review diff --base main            # against a branch
specutil review diff my-change --spec-only  # just the change artifacts
specutil web --diff --change my-change      # annotate the code in the browser
```

Two properties make the record trustworthy:

- Staleness is decided by content hash, never by a timestamp. An edit to any
  artifact reports the decision as stale rather than letting it stand, and the
  same inputs always produce the same verdict, so a record survives a rebase.
- A comment is keyed to a content-addressed identity, not a position. Renumbering
  does not move a task comment, a reworded task is re-matched by token similarity
  so its comment follows it, and a hunk's identity ignores line numbers so an edit
  elsewhere in the file does not orphan a code comment.

Gate on it by declaring the rule:

```yaml
# openspec/specutil.yaml
check:
  preset: rosh-spec-driven
  rules:
    - id: review-decision-current
      accept: [approved]           # requireRecord: false to check only reviewed changes
```

`specutil check` then fails while a change is unreviewed, is not approved, or
was edited after its approval. The `review-change` skill drives the whole loop
and shows how to wire `specutil check` to a harness stop hook.

### `web`

Generates and opens a static HTML dashboard.

```bash
specutil web [-o output.html] [--open=false]
```

The page is a single self-contained HTML file with three views:
- Kanban — lifecycle board (proposed / active / archived) with progress meters
  and each change's recorded review verdict
- Graph — the dependency DAG laid out in waves, coloured by work readiness
  (ready / in progress / blocked / waiting / done), with the critical path marked
- Detail — per-change drilldown: stages, tasks, narrative, per-stage chart, the
  working-tree diff with `--diff`, and the review panel

The Detail view is where a reviewer works. Every task takes a comment or a
removal request, tasks that moved since the last review are badged, and the
panel collects a decision and an overall note. Pass `--diff --change <name>` and
every hunk of the working-tree diff takes a comment too, so the plan and the code
it produced are judged in one pass. "Copy feedback" and "Download" produce a
single JSON document for `specutil review ingest`.

Nothing is posted anywhere. There is no server behind the page and the binary
opens no socket, so feedback leaves as a document you hand back to the CLI. A
test in `internal/guard` fails the build if the page ever grows a `fetch`, a
`WebSocket`, or a `<form>`.

Data feeds are inlined. Chart.js and Cytoscape load from a version-pinned,
SRI-protected CDN at view time. The binary performs zero network I/O.

## OpenSpec Integration

specutil reads from the standard OpenSpec directory layout. No changes to your OpenSpec authoring workflow are required.

### Directory layout

```
openspec/
├── config.yaml              # OpenSpec project config (unchanged)
├── specutil.yaml            # Cross-change dependency manifest (new)
└── changes/
    └── my-feature/
        ├── proposal.md
        ├── tasks.md
        ├── design.md
        ├── specs/
        │   └── my-cap/
        │       └── spec.md
        └── specutil.lock.yaml   # Written by `lock set` (gitignore or commit)
```

### proposal.md structure

specutil reads `## Why`, `## What Changes`, `## Capabilities`, and `## Impact` sections.

```markdown
## Why

We need X because Y.

## What Changes

- Add `foo` command that does X
- Modify `bar` to support Y

## Capabilities

### New Capabilities
- `my-capability`: Does the thing.

### Modified Capabilities
- `existing-cap`: Extends to support Y.

## Impact

- **New code:** `internal/foo`
- **Dependencies:** none new
```

### tasks.md structure

Phases are `## N. Phase Name` headings; tasks are `- [x]`/`- [ ]` checkboxes. Tasks can be tagged with `verify:`, `apply:`, or `confirm:` prefixes.

```markdown
## 1. Foundation

- [x] 1.1 Initialize the module
- [x] 1.2 verify: Build succeeds in dev shell
- [ ] 1.3 Add the core command

## 2. Integration

- [ ] 2.1 apply: Push branch and open PR (impactful)
- [ ] 2.2 confirm: CI green and PR reflects intended diff
```

### extract (composable schema conventions)

specutil reads plain OpenSpec by default: no phase shapes, no polarity, no
inline dependency fields. A repository using a spec framework with extra
convention on top of markdown declares it under `extract:` in
`openspec/specutil.yaml`:

```yaml
# openspec/specutil.yaml
extract:
  preset: rosh-spec-driven
```

If `openspec/config.yaml` already names a recognized `schema:`, specutil picks
up the matching preset automatically and no `extract:` block is needed. An
unrecognized schema name extracts nothing rather than guessing.

The built-in `rosh-spec-driven` preset understands:

| Convention | Kind | Effect |
|---|---|---|
| `- **POLARITY** positive\|negative` on a scenario | marker | groups acceptance criteria into success/error paths in every export |
| `- **SHAPE** loop\|graph` on a phase | marker | shown in the web detail view and `graph --as detail` |
| `- **STOP** <condition>` on a loop phase | marker | shown alongside shape |
| `- **MAX-ITERS** <n>` on a loop phase | marker | shown alongside shape |
| `` `deps:` 1.1, 1.2 `` on a task | field | becomes a real task-level dependency edge, driving the graph's parallelism levels instead of assuming phases are strictly sequential |

A repository can declare its own markers and fields instead of (or alongside)
a preset:

```yaml
extract:
  markers:
    - key: owner
      scope: task        # phase | task | scenario | requirement
      bullet: OWNER
  fields:
    - key: estimate
      scope: task
      label: est
      type: string        # string | list | taskRefs
```

Every declared marker and field is stripped from the prose it was written in
and carried as data instead — a tracker, a spec renderer, or `graph --as
detail` never sees the raw bullet.

### specutil.yaml (cross-change dependencies)

Declare dependencies either way. Both spellings mean the same thing and can be mixed.

```yaml
# openspec/specutil.yaml — explicit edge list
edges:
  - from: auth-redesign      # prerequisite
    to: user-profile-update  # depends on auth-redesign
  - from: auth-redesign
    to: session-management
```

```yaml
# openspec/specutil.yaml — per-change prerequisites
changes:
  user-profile-update:
    depends_on: [auth-redesign]
  session-management:
    depends_on: [auth-redesign]
```

Use `specutil graph --suggest` to see inferred candidates from shared capabilities. Edges must be confirmed and written manually (or via the agent skill) — `--suggest` never mutates the file.

### Lockfile

`specutil.lock.yaml` maps stable content hashes to external IDs. It is written only by `lock set` and read by `plan`/`diff`. Commit it alongside your changes or add it to `.gitignore` depending on your workflow.

```yaml
# openspec/changes/my-feature/specutil.lock.yaml
linear:
  abc123def:
    external_id: LIN-456
    content_hash: abc123def
    title: "Initialize the module"
```

## Integration Skills

Two skills ship in-repo to orchestrate specutil with Linear and Notion. Install them by symlinking into your skills directory or via home-manager.

### sync-to-linear

```
skills/sync-to-linear/SKILL.md
```

Flow: `plan` → review → MCP write → `lock set`. Each write is individually confirmed unless `--auto` is passed.

### sync-to-notion

```
skills/sync-to-notion/SKILL.md
```

Same flow as `sync-to-linear`, adapted for Notion pages and blocks.

## Examples

### End-to-end: render → plan → sync

```bash
# 1. Check what's in the change
specutil render --as rfc

# 2. See what would be created in Linear
specutil plan --target linear

# 3. Diff against what's already synced
specutil diff --target linear

# 4. Invoke the sync skill (agent-driven; prompts for confirmation)
# (from Claude Code or another AI shell)
# > run sync-to-linear
```

### Multi-change repository

```bash
# See all changes and their dependencies
specutil graph --as mermaid

# Infer missing dependency edges
specutil graph --suggest

# Open the visual dashboard
specutil web
```

### Custom templates

Override any shipped template by putting a file of the same name in a directory
and pointing `--templates` at it. The names are `rfc.md.tmpl`, `design.md.tmpl`,
`tickets.md.tmpl`, `ticket.md.tmpl` (one tracker ticket body), and
`overview.md.tmpl` (the change-level container body).

```bash
mkdir my-templates
# write my-templates/rfc.md.tmpl
specutil render --as rfc --templates my-templates/
```

## Development

```bash
# Enter the dev shell
nix develop

# Build
go build ./...

# Test
go test ./...

# Format Nix files
nix fmt

# Format shell scripts
task fmt:sh

# Validate the flake
nix flake check
```

### Package layout

```
cmd/specutil/             CLI entrypoint
internal/
  ir/                     Intermediate representation (framework-agnostic types)
  provider/               Provider port definition
    openspec/             OpenSpec adapter (discovery + loading)
    bmad/                 BMAD story file adapter
    plan/                 plan.md convention adapter (+ stdin)
    script/               User-defined script adapter
  registry/               Provider selection and auto-detection
  parse/                  goldmark-based lenient markdown parser
  render/                 Artifact rendering (mapping + templates + Sprig)
  graph/                  Cross-change DAG (build, project, suggest)
  extract/                Schema-declared marker/field grammar
  check/                  Rubric rules and presets
  export/                 Tracker-vocabulary projection (titles, criteria)
  detail/                 Per-change detail feed for visualizers
  syncplan/               Plan/diff/lock (content-hash identity)
  web/                    Static HTML generator
  lifecycle/              Lifecycle classification helpers
  cli/                    Cobra command wiring
skills/
  sync-to-linear/         Linear sync skill
  sync-to-notion/         Notion sync skill
  sync-to-github-issues/  GitHub Issues sync skill
openspec/                 specutil's own OpenSpec change (specutil-providers)
```

## License

MIT
