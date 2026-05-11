# rosh-spec-driven changes vs upstream `spec-driven`

This fork tracks the upstream `spec-driven` schema shipped with the
installed `openspec` CLI. Every divergence below cites the upstream file
or section being overridden. Run `hack/sync-openspec-schema.sh` to detect
upstream drift.

## Active divergences

### schema.yaml — `name`, `description`
- Upstream: `name: spec-driven`, `description: Default OpenSpec workflow ...`
- Fork: `name: rosh-spec-driven`, opinionated description.

### schema.yaml — `artifacts[id=proposal].instruction`
- Adds a `Non-goals` bullet directing the agent to fill in a `### Non-goals`
  block when the change touches more than one capability. Mirrors the
  template addition in `templates/proposal.md`.

### schema.yaml — `artifacts[id=specs].instruction`
- Adds a `rosh-spec-driven rule` bullet requiring at least one negative
  scenario per requirement.
- Adds a negative-scenario example block under the existing positive-scenario
  example so the format is unambiguous.

### schema.yaml — `artifacts[id=design].instruction`
- Adds a `rosh-spec-driven rule` clause to the Decisions bullet requiring
  each entry to list at least one alternative considered and the reason
  it was rejected.

### schema.yaml — `artifacts[id=tasks].instruction`
- Adds a `rosh-spec-driven rule` bullet requiring multi-capability changes
  to group tasks under phase headings, each phase a coherent vertical slice.

### templates/proposal.md
- Inserts a `### Non-goals` block under `## What Changes` so agents see the
  expected structure when scaffolding the file.

## Pending sync notes

- Initial fork taken from openspec 1.3.0 (`/nix/store/lwijn4py7cknh9zbvvx6icbap5gfl9ab-openspec-1.3.0/lib/openspec/schemas/spec-driven`).
- When upstream changes, `hack/sync-openspec-schema.sh` reports per-file
  diffs. Reconcile by editing this CHANGES.md and the corresponding fork
  file, never by silent overwrite.
