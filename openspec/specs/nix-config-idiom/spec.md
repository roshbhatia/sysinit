# nix-config-idiom Specification

## Purpose
Guarantee that `lib/` and `overlays/` carry no dead code, dead args, or duplicated source-of-truth, that home-manager modules prefer native `programs.<name>` options and generated-format helpers where they fit, and that platform branching uses one convention.

## Requirements

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
Where a native `programs.<name>` option or a `pkgs.formats` generator exists AND it does not replace a hand-maintained config directory, modules MUST use it instead of raw inline `home.file` text. The git attributes MUST use native `programs.git.attributes`. The `kubectl` `kuberc` MUST be generated via `pkgs.formats.yaml` from an attrset. Large inline foreign-config blocks MUST be externalized to their own file and read via `stripHeaders`/`readFile`. `yazi` is EXCLUDED: its config is a hand-maintained directory tree that `xdg.configFile.source` symlinks wholesale, which is the idiomatic path; decomposing it into `programs.yazi` attrsets is not required.

#### Scenario: git and kubectl use native/generated config
- **POLARITY** positive
- **WHEN** `modules/home/programs/git/default.nix` and `modules/home/programs/kubectl.nix` are read after the change
- **THEN** the git attributes are set through `programs.git.attributes` and `kuberc` is produced by `pkgs.formats.yaml`
- **AND** the generated `kuberc` is semantically equivalent to the prior heredoc

#### Scenario: The inline zsh block is no longer embedded
- **POLARITY** negative
- **WHEN** `modules/home/programs/zsh/default.nix` is inspected for the seshy/wezterm helper functions after the change
- **THEN** the helper body is not an inline Nix string, because it was moved to a `.zsh` file read via `stripHeaders`

### Requirement: Hand-pinned overlays are managed by nvfetcher only when the pin tracks releases
Third-party sources that track upstream releases SHOULD be managed by `nvfetcher.toml` and exposed through `_sources/generated.nix` (as `crush`, `localias`, and the go packages already are). A source that is deliberately pinned to a fixed commit, or fetched from a version-less raw URL, MUST NOT be moved to nvfetcher, because nvfetcher tracks releases and would auto-update the pin (which the repo's no-auto-update rule forbids).

#### Scenario: Release-tracking assets belong in nvfetcher
- **POLARITY** positive
- **WHEN** a new overlay fetches a package by its latest upstream release tag
- **THEN** it is added to `nvfetcher.toml` and reads its source from `final.nvfetcherSources` rather than carrying an inline hash

#### Scenario: A commit-pinned or raw-URL asset is not force-migrated
- **POLARITY** negative
- **WHEN** `wumpusMono` (pinned to a fixed commit) or `bookerly` (a raw-URL font with no version) is considered for nvfetcher
- **THEN** it is left hand-pinned, because migrating it would make nvfetcher auto-advance a deliberately-frozen source

### Requirement: One platform-branch convention
Platform branching MUST use `stdenv.hostPlatform.isDarwin` / `isLinux`. The deprecated `stdenv.isDarwin` / `stdenv.isLinux` shorthand MUST NOT remain outside `templates/`. `with lib;` SHOULD be replaced by explicit `inherit (lib) ...`, and the repeated Darwin-only override guard MAY be expressed through a shared helper; both are deferred as low-value nits and are not required by this change.

#### Scenario: Deprecated shorthand is gone
- **POLARITY** positive
- **WHEN** the repo is searched for `stdenv.isDarwin`/`stdenv.isLinux` after the change
- **THEN** no `.nix` file outside `templates/` matches the deprecated shorthand

#### Scenario: A newly added deprecated predicate is rejected
- **POLARITY** negative
- **WHEN** a new overlay or module is written using `prev.stdenv.isDarwin`
- **THEN** it does not match the established convention and MUST be changed to `stdenv.hostPlatform.isDarwin` before merge
