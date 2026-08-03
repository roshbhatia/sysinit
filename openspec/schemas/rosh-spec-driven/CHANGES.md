# rosh-spec-driven changes vs upstream `spec-driven`

This fork tracks the upstream `spec-driven` schema shipped with the
installed `openspec` CLI. Every divergence below cites the upstream file
or section being overridden. Run `hack/sync-openspec-schema.sh` to detect
upstream drift.

- The deterministic rubric-lint is now `specutil check`, not the `specreview`
  shell script. The rubric is unchanged: the same nine rules, read from the same
  declared markers. specutil parses the artifacts once and applies the rules
  from its own representation, so the format has one parser instead of two. The
  rules ship as the `rosh-spec-driven` preset, which a repository adopts by
  naming that schema in `openspec/config.yaml`. Verdict parity was confirmed by
  running both tools over every archived change. (`replace-specreview-with-specutil-check`.)

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
  `Risks`: rollout sequence, per-phase gate, kill switch, feature flags or
  config toggles. Default gate sequence for dotfiles work is
  `nix flake check → nh os build → user spot-check → nh os switch`.
- Adds a `rosh-spec-driven rule` to the `Risks` bullet: risks that map to
  human-verification checkpoints in `tasks.md` MUST be flagged here.
- Adds a `rosh-spec-driven rule` to the `Migration Plan` bullet: every step
  that mutates shared state or requires elevated permissions MUST be
  surrounded by verification and confirmation steps.
- Adds a REQUIRED `Adversarial Review` section naming the review rubric.
  Split into two halves: the deterministic `specreview` lint is MANDATORY,
  and the LLM critic loop is default-on but OWNER-GATED (the owner may waive
  the loop for a small phase, recorded as a waiver). Cites the
  `adversarial-review` skill for the methodology.

### schema.yaml — `artifacts[id=tasks].instruction`
- Adds a `rosh-spec-driven rule` bullet requiring multi-capability changes
  to group tasks under phase headings, each phase independently reviewable.
- Adds a `rosh-spec-driven rule` requiring impactful actions (`nh os switch`,
  `git push`, `openspec archive`, schema migrations, file deletions outside
  scratch, network writes, vendored-content updates, broad formatter sweeps)
  to be sandwiched between explicit `Verify:` and `Confirm:` checkpoint tasks.
- Adds a `rosh-spec-driven rule` encouraging each new-module/new-file task to
  cite the existing pattern it follows (path) or justify introducing a new one.
- Extends the example to show a `## 3. Rollout` phase with a verify/apply/confirm
  task triplet for `nh os switch`.
- Adds the per-phase adversarial-review gate rule. The checkbox is required,
  but the LLM critic loop it invokes is default-on and OWNER-GATED: the
  `adversarial-review` skill elicits approve/deny, and a deny records
  `Adversarial review: waived by owner`. The mandatory `specreview` lint is
  not gated. (`spec-driven-workflow-upgrades` change.)
- Adds the phase-shape rule. Each non-Rollout phase declares `- **SHAPE**
  loop|graph`; a `loop` also declares `- **STOP**` and `- **MAX-ITERS**`; a
  `graph` subtask may carry a trailing `` `deps:` `` whose ids resolve to
  sibling subtasks. `specreview` enforces the markers. (`spec-driven-workflow-upgrades`.)
- Adds the artifact-writing-standard rule: every artifact is written in
  Simplified Technical English per the `~/.claude/CLAUDE.md` Communication
  section. `specreview` fails on em-dashes and disallowed bolded bullet leads.
  (`spec-driven-workflow-upgrades`.)
- Adds the explicit-shape rule: model a phase as a `loop` or a `graph` rather
  than as prose. When an agent drives the iteration itself, drive it with the
  `loop` skill (`/loop` with no interval) and stop it the moment the declared
  `STOP` condition holds. A named terminal state is checkable; "until it looks
  done" is not.
- Replaces the flat `K=4` adversarial-review round cap with a cap scaled to
  blast radius (2 for one phase, 4 for one capability, 6 for a cross-capability
  or live-system change), plus early stops on non-convergence and on
  fix-induced churn. A cap hit is reported as open objections, never as a pass.
  The flat cap came from Self-Refine's max-4-iterations, which measures a
  single-model refinement loop, not an N-critic adversarial loop over a
  multi-file artifact. See the `adversarial-review` skill's methodology
  reference for the withdrawal and the observed counter-evidence.

### templates/tasks.md
- Replaces the two placeholder task groups with a `loop`-shaped and a
  `graph`-shaped example carrying the `- **SHAPE**` / `- **STOP**` /
  `- **MAX-ITERS**` / `` `deps:` `` markers. (`spec-driven-workflow-upgrades`.)

### templates/proposal.md
- Inserts a `### Non-goals` block under `## What Changes` so agents see the
  expected structure when scaffolding the file.

## Package-level divergence (not a schema-file change)

`overlays/openspec.nix` patches the built openspec `dist/` so `rosh-spec-driven`
is the machine-wide default schema (`default-rosh-spec-driven-schema` change).
This is a package patch, not a schema-template edit, so `hack/sync-openspec-schema.sh`
(which diffs only the schema template files) does not and cannot see it. The
patched default is instead guarded by `checks.<system>.openspec-default-schema`,
a hermetic behavioral flake check.

Patched sites (openspec 1.6.0), all `'spec-driven'` → `'rosh-spec-driven'`, via
`substituteInPlace ... --replace-fail` so a missed site fails the build:
- `dist/core/openspec-root.js` — `DEFAULT_OPENSPEC_SCHEMA`
- `dist/core/init.js` — `DEFAULT_SCHEMA`
- `dist/commands/workflow/shared.js` — `DEFAULT_SCHEMA`
- `dist/utils/change-utils.js` — `DEFAULT_SCHEMA`
- `dist/core/planning-home.js` — `REPO_DEFAULT_SCHEMA`
- `dist/core/root-selection.js` — inline `defaultSchema:` (read by `openspec new change`)

On a version bump, re-check these site names; `--replace-fail` fails the build on
a rename/removal, and the flake check fails on a newly added or moved site.

## add-citation-verification divergences

### schema.yaml — `artifacts[id=proposal].instruction`
- Adds rosh-spec-driven rule 5: external-factual claims require a passing
  `citations.lock` with anchored records; an unanchored claim is a default-reject.
  Bare version identifiers pinned by sha256/lockfile are excluded; prose about a
  version's behavior is not.

### schema.yaml — `artifacts[id=specs].instruction`
- Adds a rule requiring each scenario to declare polarity on a body line
  (`- **POLARITY** positive|negative`), keeping the canonical `#### Scenario:`
  heading so openspec's archive parser does not drop it. `specreview` reads the
  declared marker instead of inferring polarity from prose.

### schema.yaml — `artifacts[id=design].instruction`
- Requires each Decisions entry's rejected alternative to be on a line beginning
  `- Alternative rejected:` so `specreview` can read it.

### templates/spec.md
- Adds a `- **POLARITY**` line to the scenario skeleton.

## drop-requirement-spec-layer divergences

### schema.yaml — `artifacts[id=specs]` removed
- The fork no longer produces a requirement spec. Upstream keeps a `specs`
  artifact that emits `specs/**/*.md` deltas, which `openspec archive` promotes
  into `openspec/specs/`. The fork drops the artifact, so a change carries a
  proposal, a design, and shaped tasks, and nothing is promoted.
- Reason: the promoted corpus was never read. Over 30 archived changes it
  accumulated 42 capability specs that no later change consulted and no gate
  depended on. The acceptance criteria that mattered were already restated in
  `tasks.md` as `STOP` conditions and `Confirm:` judgments, so the spec was a
  second copy that drifted from the first.
- Every `artifacts[id=specs]` divergence recorded above is therefore moot: the
  negative-scenario rule, the polarity marker, and the delta-operation format all
  described an artifact that no longer exists. They are kept in this file as
  history, not as active divergences.
- `artifacts[id=tasks].requires` drops `specs` and now names `design` only.

### schema.yaml — `artifacts[id=proposal].instruction`
- Replaces the `Capabilities` bullet with a `Behavior` bullet. `Capabilities`
  existed only to name the spec files the next artifact would create, so it had
  no purpose once that artifact was gone. `Behavior` states the acceptance
  criteria in the proposal itself, and each entry must be decidable by a command
  or an observation.
- Retargets the review rubric from "the spec scenarios incl. negative ones" to
  the proposal `Behavior` criteria, in the `Adversarial Review` section and in
  the per-phase adversarial-review rule.

### templates/proposal.md
- Replaces the `## Capabilities` skeleton with a `## Behavior` skeleton carrying
  `Must do:` and `Must still hold:` lists, each entry naming what decides it.

### templates/spec.md removed
- The template scaffolded the removed artifact.

### Rubric change in specutil
- `specutil`'s `rosh-spec-driven` preset drops `scenario-marker-coverage`. The
  rule remains a built-in for a framework that does keep a requirement spec; no
  shipped preset selects it. `POLARITY` stays on the `bolded-bullet-lead`
  allowlist so archived spec files still lint clean.

## Pending sync notes

- Initial fork taken from openspec 1.3.0 (`/nix/store/lwijn4py7cknh9zbvvx6icbap5gfl9ab-openspec-1.3.0/lib/openspec/schemas/spec-driven`).
- When upstream changes, `hack/sync-openspec-schema.sh` reports per-file
  diffs. Reconcile by editing this CHANGES.md and the corresponding fork
  file, never by silent overwrite.
