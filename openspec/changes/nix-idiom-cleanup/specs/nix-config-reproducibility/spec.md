## ADDED Requirements

### Requirement: All package sources resolve from the lockfile
Every package source consumed at flake evaluation MUST resolve from `flake.lock`, `nvfetcher` `_sources/generated.nix`, or a `vendorHash`. No overlay or module SHALL call `fetchTarball` / `fetchGit` on an out-of-lock revision at eval time. `crossplane-cli` MUST resolve from the `nixpkgs` flake input (which provides 2.4.0) rather than an inline `fetchTarball` overlay; `overlays/crossplane.nix` MUST be deleted. The 1.17.1 -> 2.4.0 bump is an accepted owner decision.

#### Scenario: crossplane-cli comes from the locked nixpkgs
- **POLARITY** positive
- **WHEN** the flake is evaluated after the change
- **THEN** `crossplane-cli` resolves from the `nixpkgs` input at version 2.4.0
- **AND** `overlays/crossplane.nix` does not exist and `overlays/default.nix` does not import it

#### Scenario: Reintroducing an out-of-lock fetch is visible
- **POLARITY** negative
- **WHEN** any overlay in `overlays/` still contains an `import (fetchTarball ...)` of a nixpkgs archive
- **THEN** the change is incomplete and MUST be rejected at review, because the source is not pinned by `flake.lock`

### Requirement: No oversized build artifact is tracked
Build logs and transient output MUST NOT be tracked in git. `switch.err` MUST be removed from the working tree and MUST be matched by a `.gitignore` entry.

#### Scenario: switch.err is untracked and ignored
- **POLARITY** positive
- **WHEN** `git ls-files switch.err` is run after the change
- **THEN** it returns no output
- **AND** `.gitignore` contains a pattern that matches `switch.err`

#### Scenario: A regenerated switch.err stays out of the index
- **POLARITY** negative
- **WHEN** a `switch.err` file is regenerated in the repo root and `git status --porcelain` is inspected
- **THEN** the file does not appear as an untracked or staged path, because `.gitignore` excludes it
