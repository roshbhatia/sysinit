## ADDED Requirements

### Requirement: No dead code or dead arguments in lib and overlays
`lib/` and `overlays/` MUST NOT carry unused parameters, unreachable helpers, or no-op files. The broken `modules/lib/platform.nix` predicates (`hasPrefix "darwin"`, false for `aarch64-darwin`) MUST be removed or corrected. The dead `customUtils` specialArg, the unused `_system` parameter in `lib/builders/pkgs.nix`, the `_:` first-argument wrapper across overlay files, and the no-op `overlays/mozilla.nix` MUST be removed.

#### Scenario: Dead identifiers are gone
- **POLARITY** positive
- **WHEN** the repo is searched for `customUtils`, the `_:` overlay wrapper, and `overlays/mozilla.nix` after the change
- **THEN** `customUtils` appears nowhere, no overlay file opens with a `_:` throwaway arg, and `overlays/mozilla.nix` does not exist

#### Scenario: A broken platform predicate is not left callable
- **POLARITY** negative
- **WHEN** a caller evaluates a retained platform helper with a real system string such as `"aarch64-darwin"`
- **THEN** the helper returns the correct result, because no predicate matches darwin via `hasPrefix "darwin"` any longer

### Requirement: Single source of truth for PATH and shared module wiring
The PATH entry lists MUST be defined once in `modules/lib/paths.nix` and consumed by every shell module. `modules/home/programs/zsh/default.nix` MUST call `getAllPaths` rather than re-defining the arrays. The common nix-darwin and NixOS base module list MUST be defined once and shared by `lib/builders/darwin.nix` and `lib/builders/nixos.nix`.

#### Scenario: zsh consumes the shared PATH helper
- **POLARITY** positive
- **WHEN** `modules/home/programs/zsh/default.nix` is read after the change
- **THEN** it obtains its PATH entries from `modules/lib/paths.nix`
- **AND** it does not re-declare the nix/system/user/xdg PATH arrays inline

#### Scenario: A PATH edit in one place is not silently ignored
- **POLARITY** negative
- **WHEN** an entry is added to `modules/lib/paths.nix` `getSystemPaths` and the zsh and nushell PATH are compared
- **THEN** both shells receive the new entry, because neither keeps a private copy of the list

### Requirement: Native home-manager options are preferred over hand-rolled config
Where a native `programs.<name>` option or a `pkgs.formats` generator exists, modules MUST use it instead of raw `home.file` / `xdg.configFile` text. `yazi` MUST use native `programs.yazi`. The git attributes MUST use native `programs.git.attributes`. The `kubectl` `kuberc` MUST be generated via `pkgs.formats.yaml` from an attrset. Large inline foreign-config blocks MUST be externalized to their own file and read via `stripHeaders`/`readFile`.

#### Scenario: yazi and git use native options
- **POLARITY** positive
- **WHEN** `modules/home/programs/yazi/default.nix` and `modules/home/programs/git/default.nix` are read after the change
- **THEN** yazi is configured through `programs.yazi` and the git attributes are set through `programs.git.attributes`

#### Scenario: The inline zsh block is no longer embedded
- **POLARITY** negative
- **WHEN** `modules/home/programs/zsh/default.nix` is inspected for the seshy/wezterm helper functions after the change
- **THEN** the helper body is not an inline Nix string, because it was moved to a `.zsh` file read via `stripHeaders`

### Requirement: Vendored assets are fetched via nvfetcher
Third-party sources pinned by hand in overlay files MUST be managed by `nvfetcher.toml` and exposed through `_sources/generated.nix`. `contextive`, `sheets`, `wumpusMono`, and `bookerly` MUST NOT carry inline `sha256`/`hash` literals in their overlay files; their sources MUST come from `nvfetcherSources`.

#### Scenario: Migrated overlays read from nvfetcher sources
- **POLARITY** positive
- **WHEN** the `contextive`, `sheets`, `wumpusMono`, and `bookerly` overlays are read after the change
- **THEN** each obtains its source from `final.nvfetcherSources` (or `prev`) and declares no literal upstream hash

#### Scenario: A stale hand-pinned hash cannot drift silently
- **POLARITY** negative
- **WHEN** an upstream asset for one of these packages changes and `nvfetcher` is run
- **THEN** the source hash updates in `_sources/generated.nix` rather than requiring a hand edit in the overlay file, because the overlay no longer owns the hash

### Requirement: One platform-branch convention
Platform branching MUST use `stdenv.hostPlatform.isDarwin` / `isLinux`. The deprecated `stdenv.isDarwin` / `stdenv.isLinux` shorthand MUST NOT remain. `with lib;` MUST be replaced by explicit `inherit (lib) ...` in the three files that use it. The repeated Darwin-only override guard MUST be expressed through shared `overrideOnDarwin` / `useLldOnDarwin` overlay helpers.

#### Scenario: Deprecated shorthand is gone
- **POLARITY** positive
- **WHEN** the repo is searched for `stdenv.isDarwin` and `with lib;` after the change
- **THEN** no `.nix` file (outside `templates/`) matches `stdenv.isDarwin`/`stdenv.isLinux` and no file uses `with lib;`

#### Scenario: The ld64.lld guard is defined once
- **POLARITY** negative
- **WHEN** the ld64.lld RUSTFLAGS override is searched across `overlays/`
- **THEN** it is not duplicated verbatim in both `codex-acp.nix` and `overlays/default.nix`, because both call the shared `useLldOnDarwin` helper
