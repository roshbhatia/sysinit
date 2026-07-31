## MODIFIED Requirements

### Requirement: Pi packages are pinned by version + content hash

Every pi package delivered through the `packages` array in
`~/.pi/agent/settings.json` MUST be declared in
`modules/home/programs/llm/config/pi.nix` with both a version string and an SRI
hash. Packages with runtime npm dependencies MUST additionally pin a
`package-lock.json` checked into
`modules/home/programs/llm/config/locks/<package>.lock.json` and an
`npmDepsHash`. Local-path-only loading via the `packages` array is the only
supported delivery model for a package.

This requirement scopes to npm-sourced and git-sourced packages. Extension
TypeScript files read out of the `pi-coding-agent` derivation are NOT packages
and MUST NOT carry a second version string or SRI hash. They inherit the pin of
that derivation, which `_sources/generated.nix` already holds. Requiring a
second pin for them would contradict the requirement that no separately pinned
extension source exists.

#### Scenario: New package added to the registry

- **POLARITY** positive
- **WHEN** a new pi package entry is added to `pi.nix` with version, hash, and
  (if deps) lock and npmDepsHash
- **THEN** `nix build .#darwinConfigurations.lv426.system --no-link` succeeds
  and the package appears as a Nix store path
- **AND** the resulting `~/.pi/agent/settings.json` `packages` array contains
  the store path

#### Scenario: Extension files need no second pin

- **POLARITY** positive
- **WHEN** an extension TypeScript file is read from the `pi-coding-agent`
  derivation output
- **THEN** the build succeeds with no version string and no SRI hash declared
  for that file

#### Scenario: Hash drift on upstream content

- **POLARITY** negative
- **WHEN** an upstream package on the npm registry changes its tarball content
  but the pinned version string stays the same
- **THEN** the next Nix build fails with a hash mismatch error citing the
  offending package

#### Scenario: Missing lock file for a buildNpmPackage entry

- **POLARITY** negative
- **WHEN** a new package entry uses `buildNpmPackage` but no corresponding
  `locks/<package>.lock.json` is present
- **THEN** the Nix build fails with a clear error pointing at the missing lock
  path

## REMOVED Requirements

### Requirement: Source of truth for upstream extension TS files

**Reason**: The requirement pins the extension TypeScript to a revision
fetched separately from the pi binary. That mechanism is the cause of the
version skew this change removes: the pinned revision reports 0.74.0 while the
installed binary is 0.82.1. Its scenario "Pinned rev no longer exists upstream"
describes a failure mode that cannot occur once no revision is pinned, so the
requirement is replaced rather than edited.

**Migration**: The replacement requirement "Upstream extension files come from
the installed pi package" below carries the same intent. Delete
`piExtensionsRev` and `piExtensionsSrc` from `pi.nix` and read the files from
`${pkgs.pi-coding-agent}/pi/examples/extensions/`. The theme schema URL
requirement is preserved in the replacement.

## ADDED Requirements

### Requirement: Upstream extension files come from the installed pi package

The vendored upstream extension TypeScript files MUST be taken from the
installed `pi-coding-agent` derivation, which ships them under its own output.
They MUST NOT be fetched from a separately pinned source revision.

One source removes the class of defect where the extension revision and the pi
binary disagree. An extension written against one extension API version and
loaded by a different runtime fails at load time, not at build time.

The theme schema URL rendered by `pi.nix` MUST point at the canonical
`earendil-works/pi` repository.

#### Scenario: Extensions come from the installed package

- **POLARITY** positive
- **WHEN** the configuration is built
- **THEN** every vendored extension file resolves inside the installed
  `pi-coding-agent` derivation output
- **AND** `pi.nix` declares no separate extension source revision or hash

#### Scenario: A pi version bump moves the extensions with it

- **POLARITY** positive
- **WHEN** the pinned `pi-coding-agent` version is bumped
- **THEN** the vendored extension files come from the new version with no
  second hash to update

#### Scenario: A named extension missing from the package fails the build

- **POLARITY** negative
- **WHEN** an extension named in the vendor list does not exist in the
  installed package
- **THEN** the build fails and names the missing extension
- **AND** the failure does not wait for a pi session to load it

#### Scenario: A reintroduced separate revision fails the build

- **POLARITY** negative
- **WHEN** a contributor reintroduces a separately pinned extension source
- **THEN** the build fails and names the reintroduced fetcher

#### Scenario: Theme schema URL alignment

- **POLARITY** negative
- **WHEN** the rendered theme JSON's `$schema` field points at a legacy
  repository path
- **THEN** the build fails and names the stale URL
