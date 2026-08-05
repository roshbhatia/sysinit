# openspec-customization Specification

## Purpose
TBD - created by archiving change supercharge-agent-skills. Update Purpose after archive.
## Requirements
### Requirement: A packaged schema captures recurring authoring rules
The OpenSpec package MUST include `rosh-spec-driven` beside its upstream schemas. The source at `overlays/openspec/rosh-spec-driven/` SHALL encode the user's recurring authoring rules.

#### Scenario: Schema is discoverable
- **WHEN** `openspec schema which rosh-spec-driven` is run outside this repository with an empty XDG data directory
- **THEN** it reports `Source: package`

#### Scenario: Schema validates
- **WHEN** `openspec schema validate rosh-spec-driven` is run
- **THEN** it exits zero with no warnings

### Requirement: Schema additions beyond upstream are documented
Every change made to the custom schema relative to upstream `spec-driven` MUST be documented in `overlays/openspec/rosh-spec-driven/CHANGES.md` with one bullet per rule.

#### Scenario: Undocumented divergence caught
- **WHEN** a template file in the fork differs from upstream but `CHANGES.md` does not mention it
- **THEN** `hack/sync-openspec-skills.sh` (or the equivalent diff script) prints a warning naming the undocumented file

### Requirement: Projects reference the fork through config.yaml
Each personal project's `openspec/config.yaml` that participates in this workflow MUST set `schema: rosh-spec-driven`. The installed OpenSpec package provides the schema globally.

#### Scenario: Sysinit uses the fork
- **WHEN** `openspec config get schema` is run in the sysinit repo
- **THEN** the response reports `schemaName: rosh-spec-driven`

#### Scenario: Foreign project picks up the fork
- **WHEN** a user copies the documented `openspec/config.yaml` snippet into a new project and runs `openspec status --json`
- **THEN** the response reports `schemaName: rosh-spec-driven`

### Requirement: Upstream drift is detected, not auto-merged
A maintenance script MUST exist that diffs the forked schema against the upstream `spec-driven` schema shipped with the currently-installed openspec version, and reports any upstream files whose hashes have changed since the last sync. The script SHALL NOT modify the fork; it only reports.

#### Scenario: Upstream change reported
- **WHEN** openspec is bumped to a version where upstream `spec-driven/templates/proposal.md.hbs` has changed and `hack/sync-openspec-schema.sh` is run
- **THEN** the script prints a diff for that file and exits non-zero so CI can flag the drift

### Requirement: Manual rules encoded as schema-level constraints
At minimum, the fork MUST encode the following rules into the appropriate templates or instructions (placement determined when authoring the schema, but each MUST be enforced by the schema rather than relying on per-session reminders):

- Proposals MUST include a "Non-goals" subsection under "What Changes" when scope ambiguity is plausible.
- `tasks.md` MUST chunk work into named phases when the change touches more than one capability.
- Every `specs/<cap>/spec.md` requirement MUST have at least one negative scenario (a "WHEN <unexpected condition> THEN <error/rejection>" pair).
- `design.md` MUST contain a "Decisions" section that records, per decision, the alternatives considered and why they were rejected.

#### Scenario: Negative scenario rule enforced at validate time
- **WHEN** a spec.md adds a requirement with only positive scenarios and `openspec validate` is run
- **THEN** the command warns or errors with a message that references the negative-scenario rule

#### Scenario: Non-goals reminder appears at propose time
- **WHEN** an agent invokes `openspec instructions proposal --change <name>`
- **THEN** the returned `instruction` text mentions the Non-goals requirement when the change touches more than one capability

### Requirement: The custom schema resolves from the package

The OpenSpec derivation MUST install `rosh-spec-driven` under its package
schema directory. Resolution MUST NOT depend on a project-local schema or an
XDG user override.

#### Scenario: Fork resolves outside sysinit

- **POLARITY** positive
- **WHEN** `openspec schema which rosh-spec-driven` runs from a directory that is not the sysinit repo and has no project-local schema
- **THEN** it reports `Source: package`

#### Scenario: XDG data is empty

- **POLARITY** positive
- **WHEN** a temporary project uses an empty `XDG_DATA_HOME`
- **THEN** `openspec new change` still resolves `rosh-spec-driven`

#### Scenario: Package omits the custom schema

- **POLARITY** negative
- **WHEN** the package output does not contain `rosh-spec-driven/schema.yaml`
- **THEN** the default-schema check fails

### Requirement: Bare init and resolution default to the fork

The openspec overlay MUST patch every default-schema assignment site in the built `dist/` from `spec-driven` to `rosh-spec-driven`, not only the named constants. As of openspec 1.6.0 the sites are: `core/openspec-root.js` (`DEFAULT_OPENSPEC_SCHEMA`), `core/init.js` (`DEFAULT_SCHEMA`), `commands/workflow/shared.js` (`DEFAULT_SCHEMA`), `utils/change-utils.js` (`DEFAULT_SCHEMA`), `core/planning-home.js` (`REPO_DEFAULT_SCHEMA`), and the inline object-literal property `defaultSchema: 'spec-driven'` in `core/root-selection.js`, which is the value `openspec new change` actually reads via `root.defaultSchema`. A bare `openspec init` or `openspec new change` with no `--schema` flag SHALL select `rosh-spec-driven`.

#### Scenario: Fresh init picks the fork

- **WHEN** `openspec init` is run in a new project with no prior config and no `--schema` flag
- **THEN** the written `openspec/config.yaml` sets `schema: rosh-spec-driven`

#### Scenario: Patched default resolves its packaged schema

- **WHEN** the default is patched to `rosh-spec-driven` and XDG data is empty
- **THEN** the command resolves the packaged schema without falling back to `spec-driven`

### Requirement: The shared-repo practice is documented and the failure is explicit

Because the fork is the machine-wide default but is deliberately not distributed, a bare `openspec init` in a shared repo writes `schema: rosh-spec-driven` into committed config that no teammate can resolve. This change does not add a commit-time guard (judged not worth the cost for a single user). Instead, `AGENTS.md` MUST document the shared-repo practice: in a repo shared with others, pin `schema: spec-driven` or run `openspec init --schema spec-driven`. The residual failure is bounded because a teammate who does pull the fork name gets an explicit "schema not found" error that names the available schemas, not a silent misbehavior.

#### Scenario: Shared-repo practice is documented

- **WHEN** a reader consults `AGENTS.md` after this change
- **THEN** it states that shared repos pin `schema: spec-driven` and explains why the fork is not distributed

#### Scenario: Teammate on a leaked config gets an explicit error

- **WHEN** a teammate without the fork pulls a committed `openspec/config.yaml` naming `schema: rosh-spec-driven` and runs `openspec validate`
- **THEN** it fails with an explicit "schema not found" error naming the available schemas, rather than silently falling back or misbehaving

### Requirement: The patch fails loudly and its health is checked, not assumed

The overlay patch MUST fail the build if any known target site does not match. A separate `nix flake check` MUST use empty HOME and XDG directories, resolve the packaged schema, run `openspec new change probe`, and assert the written config names `rosh-spec-driven`. This exercises the installed result. The patch MUST be recorded in `overlays/openspec/rosh-spec-driven/CHANGES.md`.

#### Scenario: Removed known site fails the build

- **WHEN** an openspec version bump renames or removes a known default-schema site so a `--replace-fail` target no longer matches
- **THEN** the overlay build fails loudly, rather than silently reverting the default

#### Scenario: New controlling site caught by the behavioral test

- **WHEN** a version bump routes the default through a site the patch does not touch, so the effective default is still `spec-driven`
- **THEN** the hermetic flake-check `openspec new change probe` writes `schema: spec-driven`, the assertion fails, and `nix flake check` fails

#### Scenario: Undocumented patch caught

- **WHEN** the overlay patches the default but `CHANGES.md` does not record it
- **THEN** the review gate for this change treats the omission as incomplete and the phase is not marked done

### Requirement: The schema requires a citations.lock for external-factual claims

The `rosh-spec-driven` schema MUST require that a change containing external-factual claims (pricing, availability, external API behavior, cited papers) carries a `citations.lock` that passes `citelock`. The exclusion is scoped narrowly: a sha256 or lockfile pin (`nvfetcher` `_sources`, `flake.lock`, `vendorHash`) excludes only the bare version identifier it pins, because the hash is provenance for the fetched bytes. Any prose claim about that version's behavior, history, or capabilities (for example "the first release with fix X", "this version adds Y") is NOT covered by the pin and remains in the claim class. This separates byte-provenance from claim-provenance, so a routine bump with no descriptive prose needs no lock, while a bump whose prose asserts a fact about the version does. An unresolved or unanchored external-factual claim is a named default-reject, in the same register as the "parallel infrastructure" default-reject. Prefer original sources and record why a secondary source is necessary. The rule MUST be encoded in the proposal and design instructions and recorded in `overlays/openspec/rosh-spec-driven/CHANGES.md`.

The determination of whether a change "has external-factual claims" is a review-gate judgment (the author and the adversarial-review critics), not a mechanical one. `citelock` is mechanical only once a `citations.lock` exists: it is a no-op that exits zero when no lock is present. The schema rule closes the gap by making an unanchored claim a default-reject at the review gate, so a missing lock on a change that clearly makes external claims is caught by review, not silently passed.

#### Scenario: Claim rule surfaced at authoring time
- **POLARITY** positive
- **WHEN** an agent invokes `openspec instructions proposal --change <name>` for a change with external-factual claims
- **THEN** the returned instruction text states that a `citations.lock` is required and that an unanchored claim is a default-reject

#### Scenario: Unanchored claim blocks the review gate
- **POLARITY** negative
- **WHEN** a change asserts an external-factual claim with no matching passing record in `citations.lock`
- **THEN** the review gate treats the change as default-reject and the phase is not marked done

#### Scenario: Change with no external claims is not blocked
- **POLARITY** positive
- **WHEN** a change makes no external-factual claims and carries no `citations.lock`
- **THEN** `citelock` exits zero as a no-op and the review gate does not require a lock

#### Scenario: Bare version bump is not blocked
- **POLARITY** positive
- **WHEN** a change only bumps `nvfetcher` `_sources`, `flake.lock`, or a sha256-pinned version and its prose asserts no fact about the version beyond the identifier
- **THEN** the review gate does not require a lock, because the pin is provenance for the bare version

#### Scenario: Version bump with a descriptive claim needs a lock
- **POLARITY** negative
- **WHEN** a bump's prose asserts a fact about the version (for example "the first release with fix X") not attested by the sha256
- **THEN** that prose is in the claim class and the review gate requires a `citations.lock` record for it

### Requirement: Proposals name the human-owned decision

Every proposal MUST state which judgment remains with the owner. Automation
evidence and model critique MUST NOT represent that approval.

#### Scenario: Proposal states the owner judgment

- **POLARITY** positive
- **WHEN** a proposal is ready for review
- **THEN** its Behavior section names the human-owned decision

#### Scenario: Automation claims the decision

- **POLARITY** negative
- **WHEN** a proposal treats a passing command or model verdict as owner approval
- **THEN** review rejects the proposal
