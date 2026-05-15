# pi-package-vendoring Specification

## Purpose
TBD - created by archiving change refresh-pi-stack. Update Purpose after archive.
## Requirements
### Requirement: Pi packages are pinned by version + content hash
Every pi extension and pi CLI tool consumed by this dotfiles repo MUST be declared in `modules/home/programs/llm/config/pi.nix` with both a version string and an SRI hash. Packages with runtime npm dependencies MUST additionally pin a `package-lock.json` checked into `modules/home/programs/llm/config/locks/<package>.lock.json` and an `npmDepsHash`. Local-path-only loading via `~/.pi/agent/settings.json` `packages` array is the only supported delivery model.

#### Scenario: New package added to the registry
- **WHEN** a new pi package entry is added to `pi.nix` with version, hash, and (if deps) lock + npmDepsHash
- **THEN** `nix build .#darwinConfigurations.demiurge.system --no-link` succeeds and the package appears as a Nix store path
- **AND** the resulting `~/.pi/agent/settings.json` `packages` array contains the store path

#### Scenario: Hash drift on upstream content
- **WHEN** an upstream package on the npm registry changes its tarball content but the pinned version string stays the same
- **THEN** the next Nix build fails with a hash mismatch error citing the offending package

#### Scenario: Missing lock file for a buildNpmPackage entry
- **WHEN** a new package entry uses `buildNpmPackage` but no corresponding `locks/<package>.lock.json` is present
- **THEN** the Nix build fails with a clear error pointing at the missing lock path

### Requirement: Required pi packages baseline
The package list in `pi.nix` MUST include, at minimum, the following names so every fresh install picks them up automatically: `pi-annotated-reply`, `pi-mermaid`, `pi-context`, `pi-subagents`, `pi-readline-search`, `pi-rtk`, `pi-threads`, `pi-interview`, `pi-librarian`, `pi-ask-user`, `pi-tool-display`, `pi-subdir-context`, `pi-dcp`, `pi-webfetch-to-markdown`, `pi-mcp-adapter`, `@heyhuynhgiabuu/pi-diff`, `taskplane`, `@plannotator/pi-extension`, `pi-btw`, `@samfp/pi-memory`, `@gotgenes/pi-permission-system`, `@benvargas/pi-claude-code-use`, `@benvargas/pi-openai-fast`, `@benvargas/pi-openai-verbosity`, `@firstpick/pi-extension-reverse-last`, `@juicesharp/rpiv-advisor`.

#### Scenario: Fresh checkout includes the baseline
- **WHEN** a user clones sysinit on a clean machine and runs `nh darwin switch .`
- **THEN** every required package name above resolves to a Nix store path referenced in `~/.pi/agent/settings.json`

#### Scenario: A required package is removed from the registry attrset
- **WHEN** a contributor deletes one of the required package entries from `pi.nix` and runs `nix flake check`
- **THEN** the build fails or `~/.pi/agent/settings.json` is missing that package's store path, surfacing the regression before activation

### Requirement: Orphan lock files are forbidden
`modules/home/programs/llm/config/locks/` MUST NOT contain a lock file whose corresponding package is not present in `pi.nix`. The current orphan `pi-pretty.lock.json` is REMOVED.

#### Scenario: Stale lock detected
- **WHEN** the `locks/` directory contains `<name>.lock.json` but `pi.nix` references no package named `<name>` or `pi-<name>` or `@<scope>/pi-<name>`
- **THEN** the maintenance script `hack/update-pi.sh` reports the orphan and exits non-zero

### Requirement: Source of truth for upstream extension TS files
The vendored upstream extension TypeScript files MUST be fetched from the canonical `earendil-works/pi` repository, not from the legacy `badlogic/pi-mono` redirect. The pinned revision MUST be recorded in `pi.nix` as `piExtensionsRev` and bumped together with `piExtensionsSrc.sha256`.

#### Scenario: Theme schema URL alignment
- **WHEN** the rendered theme JSON's `$schema` field is inspected
- **THEN** the URL points at `https://raw.githubusercontent.com/earendil-works/pi/main/...` not at the legacy `badlogic/pi-mono` path

#### Scenario: Pinned rev no longer exists upstream
- **WHEN** the pinned rev is force-pushed away or the upstream repo is deleted/moved
- **THEN** the next `nix build` fails with a fetch error rather than silently substituting a different commit

### Requirement: Drift detection script
A `hack/update-pi.sh` script MUST exist that, for every npm-sourced pi package pinned in `pi.nix`, queries the npm registry for the latest version and prints a per-package report of pinned-vs-latest. The script SHALL recompute SRI hashes using the fake-hash technique already used by `hack/update-openspec.sh`. The script MUST exit non-zero when any drift is detected, and MUST NOT auto-modify `pi.nix` in its default mode.

#### Scenario: All pins are current
- **WHEN** every pinned package matches its npm `latest` and every hash is correct
- **THEN** the script reports "OK: pi packages current" and exits zero

#### Scenario: One package is stale
- **WHEN** a package is one or more versions behind its npm `latest`
- **THEN** the script reports the package name, pinned version, and latest version, and exits non-zero

#### Scenario: Script run without network
- **WHEN** the script runs without network access to the npm registry
- **THEN** it reports the connectivity failure and exits non-zero rather than reporting false "current"

