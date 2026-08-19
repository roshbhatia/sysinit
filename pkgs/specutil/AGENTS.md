# Agent context for specutil

Read this before changing anything under `pkgs/specutil/`.

## What this is

A pure, local Go CLI. It reads OpenSpec change artifacts from the filesystem.
It projects them into rendered documents, a dependency graph, a browser view, a
rubric lint, and a review record. It performs no network I/O.

It was a standalone repository (`roshbhatia/specutil`) until 2026-08-11, when it
was vendored here and the upstream was archived. Build it with the sysinit flake,
not with a Taskfile or a nested `nix develop`.

## Repository map

```
cmd/specutil/     entry point: parse flags, call cli.NewRootCmd
internal/
  cli/            cobra command tree; every verb is wired here
  ir/             normalized intermediate representation
  provider/       the inbound port, plus its one adapter: openspec
  registry/       resolves the provider and decorates it with extract
  extract/        schema-declared marker and field grammar
  parse/          markdown to IR, tolerantly
  check/          rubric rules and per-schema presets
  ident/          content-addressed task handles
  review/         a human verdict: record, drift, agent brief
  vcs/            local git working-tree diff, parsed into files and hunks
  lifecycle/      change state and the runnable-subtask calculation for `next`
  export/         IR to reader-facing vocabulary
  render/         IR to RFC, design, or ticket-list markdown
  graph/          dependency DAG as json, mermaid, or dot
  detail/         per-change detail feed the web page inlines
  web/            HTML page, embedded assets, annotation surface
  guard/          tests that hold the invariants below
skills/           agent skills: discover-deps, review-change
```

## The invariants, and what holds them

Each of these has a test in `internal/guard`. Read the test before arguing with
the rule.

The binary never makes a network call. `TestNoNetworkImportsInBinary` walks every
non-test file and fails on a `net`, `net/http`, or `net/smtp` import. Anything
that needs credentials or a remote API belongs in a skill, driven by the agent's
own MCP tools.

The web page exports; it never posts. No `fetch`, no `WebSocket`, no `<form>`, no
server. Feedback leaves as a document the reader copies or downloads, and
`specutil review ingest` folds it back in. `TestWebFeedbackIsExportedNotPosted`
fails the build if that changes.

Staleness is a hash, never a timestamp. A review record fingerprints the
artifacts it describes, so two runs over one repository agree and a record
survives a checkout. When you change what `review.ChangeHash` covers, bump
`review.RecordVersion` and raise `hashComparableFrom`, or every stored hash
silently reports stale.

## Schema conventions are declared, never branched on

specutil supports plain OpenSpec. A schema can layer extra convention on
markdown: a scenario's polarity, a phase's shape, an inline task-dependency
field. It declares that under `extract:` in `openspec/specutil.yaml`. Otherwise
it comes from a built-in preset, keyed on the schema name in its own
`openspec/config.yaml`.

If you write `if schema == "..."` anywhere outside `internal/extract` or
`internal/check`, stop: that knowledge belongs in a preset. The same rule governs
a rubric rule, which is generic and takes parameters; the schema-specific values
live only in `internal/check/presets.go`.

## Identity has one definition

`internal/ident` defines identity (normalized, edit-tolerant), content hash
(exact), and similarity (token Jaccard). `review` and `vcs` both call it. A
hunk's handle comes from its changed lines alone, so an edit elsewhere in the
file does not orphan a comment. Call `ident`; never re-derive a handle.

## Making changes

Adding a check rule:

1. Register it in `internal/check/rules.go` with an ID, a one-line doc, and
   parameters. The doc is what `specutil check --list-rules` prints.
2. Read only stated facts: a heading, a declared marker, a bullet ordering. A
   rule that infers intent from prose is not reproducible.
3. Reference it from a preset if a schema needs it.
4. Test the pass case and the fail case.

Adding a render format:

1. Declare its section routing in `render/mapping.go`.
2. Write the template in `render/templates/`. Read `.Export` for anything a
   reader outside the repository sees; `.Change` is raw IR and carries source
   numbering.
3. Cover it in `internal/cli/cli_test.go`, following `TestRenderRFC`.

## Testing

```bash
go test ./...          # 19 packages
go test -race ./...    # before committing
```

`overlays/gotools.nix` runs `go test ./...` over the whole `pkgs/` module as
its check phase, so a failing test here fails every tool's build. Do not set
`subPackages` there. It narrows the check phase as well as the build, and the
`main` packages hold no tests, so the build would pass having run nothing.

Integration tests call `cli.NewRootCmd()` and `Execute()` directly, never
`os/exec`. Fixtures live in `internal/cli/testdata/`; use `setupMinimalOpenspec`
for a bare tree and `fixture("getting-started")` for a realistic one.

## What not to do

Do not add a sync verb, a tracker lockfile, or a second input provider. All
three existed and were removed on 2026-08-11, because nothing on this host used
them. A `git log` on this directory has the reasoning. To file work in a tracker, run
`specutil render --as tickets` and write it with the tracker's own MCP tools.

Do not write source numbering into anything a tracker or an outside reader sees.
Route it through `internal/export`.

Do not add global state, an `init` that does I/O, or a package-level client.

Do not add a dependency without discussion. The surface is deliberately small.
