## ADDED Requirements

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
- **THEN** the review gate for this change treats the omission as incomplete and the slice is not marked done
