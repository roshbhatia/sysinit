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
- Adds four numbered `rosh-spec-driven rules` block: (1) reuse existing patterns
  before introducing new ones, citing paths; (2) shape every change for
  progressive rollout (each capability reviewable/buildable/verifiable
  independently); (3) flag impactful actions in `Impact` so they become
  human-verification checkpoints in `tasks.md`; (4) name the gating signal
  (default for dotfiles: `nh os build` before `nh os switch`).

### schema.yaml — `artifacts[id=specs].instruction`
- Adds a `rosh-spec-driven rule` bullet requiring at least one negative
  scenario per requirement.
- Adds a negative-scenario example block under the existing positive-scenario
  example so the format is unambiguous.

### schema.yaml — `artifacts[id=design].instruction`
- Adds a `rosh-spec-driven rule` clause to the Decisions bullet requiring
  each entry to list at least one alternative considered and the reason
  it was rejected.
- Adds a `rosh-spec-driven rule` to the `Context` bullet: name existing
  patterns/files being extended, cite paths; justify any new pattern.
- Adds a new REQUIRED `Rollout & Gating` section between `Decisions` and
  `Risks`: rollout sequence, per-slice gate, kill switch, feature flags or
  config toggles. Default gate sequence for dotfiles work is
  `nix flake check → nh os build → user spot-check → nh os switch`.
- Adds a `rosh-spec-driven rule` to the `Risks` bullet: risks that map to
  human-verification checkpoints in `tasks.md` MUST be flagged here.
- Adds a `rosh-spec-driven rule` to the `Migration Plan` bullet: every step
  that mutates shared state or requires elevated permissions MUST be
  surrounded by verification and confirmation steps.

### schema.yaml — `artifacts[id=tasks].instruction`
- Adds a `rosh-spec-driven rule` bullet requiring multi-capability changes
  to group tasks under phase headings, each phase a coherent vertical slice.
- Adds a `rosh-spec-driven rule` requiring impactful actions (`nh os switch`,
  `git push`, `openspec archive`, schema migrations, file deletions outside
  scratch, network writes, vendored-content updates, broad formatter sweeps)
  to be sandwiched between explicit `Verify:` and `Confirm:` checkpoint tasks.
- Adds a `rosh-spec-driven rule` encouraging each new-module/new-file task to
  cite the existing pattern it follows (path) or justify introducing a new one.
- Extends the example to show a `## 3. Rollout` phase with a verify/apply/confirm
  task triplet for `nh os switch`.

### templates/proposal.md
- Inserts a `### Non-goals` block under `## What Changes` so agents see the
  expected structure when scaffolding the file.

## Pending sync notes

- Initial fork taken from openspec 1.3.0 (`/nix/store/lwijn4py7cknh9zbvvx6icbap5gfl9ab-openspec-1.3.0/lib/openspec/schemas/spec-driven`).
- When upstream changes, `hack/sync-openspec-schema.sh` reports per-file
  diffs. Reconcile by editing this CHANGES.md and the corresponding fork
  file, never by silent overwrite.
