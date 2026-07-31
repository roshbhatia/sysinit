# openspec-customization Specification

## Purpose
TBD - created by archiving change supercharge-agent-skills. Update Purpose after archive.
## Requirements
### Requirement: A forked schema captures recurring authoring rules
A project-local OpenSpec schema MUST exist at `openspec/schemas/rosh-spec-driven/`, forked from the upstream `spec-driven` schema via `openspec schema fork spec-driven rosh-spec-driven`. The fork SHALL be the place where the user's recurring "manual rules" for proposal/design/tasks/specs authoring are encoded.

#### Scenario: Schema is discoverable
- **WHEN** `openspec schema which rosh-spec-driven` is run from the repo root
- **THEN** it reports the path `openspec/schemas/rosh-spec-driven/`

#### Scenario: Schema validates
- **WHEN** `openspec schema validate rosh-spec-driven` is run
- **THEN** it exits zero with no warnings

### Requirement: Schema additions beyond upstream are documented
Every change made to the forked schema relative to upstream `spec-driven` MUST be documented in `openspec/schemas/rosh-spec-driven/CHANGES.md` with one bullet per rule, citing the upstream file or section being overridden.

#### Scenario: Undocumented divergence caught
- **WHEN** a template file in the fork differs from upstream but `CHANGES.md` does not mention it
- **THEN** `hack/sync-openspec-skills.sh` (or the equivalent diff script) prints a warning naming the undocumented file

### Requirement: Projects reference the fork through config.yaml
Each project's `openspec/config.yaml` that participates in this workflow MUST set `schema: rosh-spec-driven` (resolved either by local path or by Git URL once published). The sysinit repo's own `openspec/config.yaml` SHALL reference the local fork by relative path.

#### Scenario: Sysinit uses the fork
- **WHEN** `openspec config get schema` is run in the sysinit repo
- **THEN** the resolved value points at `openspec/schemas/rosh-spec-driven/`

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

### Requirement: The fork resolves in every project via the XDG user override

The forked schema MUST be installed to the XDG user-override directory (`$XDG_DATA_HOME/openspec/schemas/rosh-spec-driven/`, default `~/.local/share/openspec/schemas/rosh-spec-driven/`) by home-manager, sourced from the in-repo `openspec/schemas/rosh-spec-driven/`. The install is a rebuild-gated snapshot: `nh darwin switch` copies the current repo files into the store and links the XDG path at them, so the repo is the only authoring site and a working-tree edit takes effect on the next rebuild. The spec makes no zero-drift claim between rebuilds; that snapshot behavior is the same as every other nix-managed file in this repo.

#### Scenario: Fork resolves outside sysinit

- **WHEN** `openspec schema which rosh-spec-driven` is run from a directory that is not the sysinit repo and has no project-local schema
- **THEN** it reports the schema with `Source: user` and a path under `$XDG_DATA_HOME/openspec/schemas/rosh-spec-driven`

#### Scenario: XDG install missing

- **WHEN** the XDG user-override directory does not contain `rosh-spec-driven/schema.yaml` and a foreign project sets `schema: rosh-spec-driven`
- **THEN** `openspec validate` fails with a "schema not found" error naming the available schemas, rather than silently falling back to `spec-driven`

### Requirement: Bare init and resolution default to the fork

The openspec overlay MUST patch every default-schema assignment site in the built `dist/` from `spec-driven` to `rosh-spec-driven`, not only the named constants. As of openspec 1.6.0 the sites are: `core/openspec-root.js` (`DEFAULT_OPENSPEC_SCHEMA`), `core/init.js` (`DEFAULT_SCHEMA`), `commands/workflow/shared.js` (`DEFAULT_SCHEMA`), `utils/change-utils.js` (`DEFAULT_SCHEMA`), `core/planning-home.js` (`REPO_DEFAULT_SCHEMA`), and the inline object-literal property `defaultSchema: 'spec-driven'` in `core/root-selection.js`, which is the value `openspec new change` actually reads via `root.defaultSchema`. A bare `openspec init` or `openspec new change` with no `--schema` flag SHALL select `rosh-spec-driven`.

#### Scenario: Fresh init picks the fork

- **WHEN** `openspec init` is run in a new project with no prior config and no `--schema` flag
- **THEN** the written `openspec/config.yaml` sets `schema: rosh-spec-driven`

#### Scenario: Patched default with no resolvable schema

- **WHEN** the default is patched to `rosh-spec-driven` but the XDG override is absent and the project has no local fork
- **THEN** the command fails with an explicit "schema not found" error, and MUST NOT fall back to upstream `spec-driven` without a message

### Requirement: The shared-repo practice is documented and the failure is explicit

Because the fork is the machine-wide default but is deliberately not distributed, a bare `openspec init` in a shared repo writes `schema: rosh-spec-driven` into committed config that no teammate can resolve. This change does not add a commit-time guard (judged not worth the cost for a single user). Instead, `AGENTS.md` MUST document the shared-repo practice: in a repo shared with others, pin `schema: spec-driven` or run `openspec init --schema spec-driven`. The residual failure is bounded because a teammate who does pull the fork name gets an explicit "schema not found" error that names the available schemas, not a silent misbehavior.

#### Scenario: Shared-repo practice is documented

- **WHEN** a reader consults `AGENTS.md` after this change
- **THEN** it states that shared repos pin `schema: spec-driven` and explains why the fork is not distributed

#### Scenario: Teammate on a leaked config gets an explicit error

- **WHEN** a teammate without the fork pulls a committed `openspec/config.yaml` naming `schema: rosh-spec-driven` and runs `openspec validate`
- **THEN** it fails with an explicit "schema not found" error naming the available schemas, rather than silently falling back or misbehaving

### Requirement: The patch fails loudly and its health is checked, not assumed

The overlay patch MUST fail the build if any known target site does not match (for example `substituteInPlace ... --replace-fail`). Because `--replace-fail` is blind to a newly added or moved controlling site, a separate `nix flake check` MUST run a hermetic behavioral test: set `HOME` and `XDG_DATA_HOME` to temp dirs, copy the in-repo `rosh-spec-driven` schema into the temp `$XDG_DATA_HOME/openspec/schemas/`, run `openspec new change probe` in a temp project with no network, and assert the written `config.yaml` names `rosh-spec-driven`. It MUST be a flake check, not an `installCheckPhase` inside the openspec derivation, so the schema source does not pull the whole repo tree into the openspec derivation inputs and defeat its cache. This exercises the real resolution path, so a bump that routes the default through a new site fails the check. `hack/sync-openspec-schema.sh` cannot catch this because it never sees `dist/*.js`. The patch MUST be recorded in `openspec/schemas/rosh-spec-driven/CHANGES.md`.

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

The `rosh-spec-driven` schema MUST require that a change containing external-factual claims (pricing, availability, external API behavior, cited papers) carries a `citations.lock` that passes `citelock`. The exclusion is scoped narrowly: a sha256 or lockfile pin (`nvfetcher` `_sources`, `flake.lock`, `vendorHash`) excludes only the bare version identifier it pins, because the hash is provenance for the fetched bytes. Any prose claim about that version's behavior, history, or capabilities (for example "the first release with fix X", "this version adds Y") is NOT covered by the pin and remains in the claim class. This separates byte-provenance from claim-provenance, so a routine bump with no descriptive prose needs no lock, while a bump whose prose asserts a fact about the version does. An unresolved or unanchored external-factual claim is a named default-reject, in the same register as the "parallel infrastructure" default-reject. The rule MUST be encoded in the proposal and design instructions and recorded in `openspec/schemas/rosh-spec-driven/CHANGES.md`.

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

