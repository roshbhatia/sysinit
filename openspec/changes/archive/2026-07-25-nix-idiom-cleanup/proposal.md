## Why

An idiom audit of the Nix config found one reproducibility hole, one security default, and a set of dead-code and hand-rolled patterns that duplicate what nixpkgs, home-manager, and nvfetcher already provide. The reproducibility and security items can bite silently, so fix them now and remove the surrounding drift in the same pass.

## What Changes

- Delete `overlays/crossplane.nix`, whose impure `fetchTarball` pins `crossplane-cli` to 1.17.1; use `pkgs.crossplane-cli` from the main nixpkgs input. **BREAKING**: this bumps crossplane-cli 1.17.1 -> 2.4.0 (crossplane v1 -> v2), an accepted owner decision. Removes the only out-of-lock eval-time source.
- Remove the 33MB tracked `switch.err` build log and add it to `.gitignore`.
- Delete the dead, broken `modules/lib/platform.nix` (its `hasPrefix "darwin"` predicates are false for `aarch64-darwin`; zero live consumers). Keep only `getBrewPrefix`/`getBrewArchitecture` if still needed, fixed.
- Extract a shared base-module list from `lib/builders/darwin.nix` and `lib/builders/nixos.nix`; remove the dead `customUtils` specialArg, the unused `_system` param in `lib/builders/pkgs.nix`, and the re-export hop in `lib/builders.nix`.
- Make `modules/home/programs/zsh/default.nix` consume `modules/lib/paths.nix` `getAllPaths` instead of re-defining the PATH arrays.
- Drop the dead `_:` wrapper arg across the 25 overlay files; delete the no-op `overlays/mozilla.nix`; feed `inputs` to `overlays/inputs.nix` via a closure in `overlays/default.nix`.
- Externalize the ~80-line inline Bash block in `zsh/default.nix` to a `.zsh` file read via `stripHeaders`.
- Use native `programs.git.attributes` and `pkgs.formats.yaml` for the `kubectl` `kuberc` heredoc.
- Migrate all 20 deprecated `stdenv.isDarwin`/`isLinux` uses to `stdenv.hostPlatform.*`.
- DROPPED after inspection: the `yazi` native-module switch (its config is a hand-maintained directory that `xdg.configFile.source` symlinks; native attrsets would be more churn) and the `contextive`/`sheets`/`wumpusMono`/`bookerly` nvfetcher migration (`wumpusMono` is commit-pinned and `bookerly` is a version-less raw URL; nvfetcher would auto-update the intentional pins).
- DEFERRED as low-value nits: the `useLldOnDarwin`/`overrideOnDarwin` overlay helpers, the 2 remaining `with lib;` uses, and the `ssh.*` namespace move.

### Non-goals

- No migration to flake-parts or flake-utils. The hand-rolled builders stay; only their duplication and dead args are removed.
- No runtime behavior change for any tool. Every module and overlay edit MUST produce byte-identical or intentionally-equivalent generated output.
- No changes to the `llm/` subsystem, `neovim/`, or `wezterm/` Lua config beyond the named `stdenv`/`with lib;` nits.
- No `flake.lock` input changes. `crossplane-cli` moves to the existing `nixpkgs` input (which provides 2.4.0). The 1.17.1 -> 2.4.0 bump is the one intentional exception to "no version change", accepted by the owner.
- No change to `NODE_TLS_REJECT_UNAUTHORIZED`. It stays global by owner decision (it exists for Cursor).
- No git history rewrite to purge `switch.err` from past commits (removal from the tree only).

## Capabilities

### New Capabilities
- `nix-config-reproducibility`: every package source resolves from `flake.lock` or nvfetcher `_sources`; no impure network fetch at eval; no oversized build artifact is tracked.
- `nix-config-idiom`: no dead code, dead args, or duplicated source-of-truth in `lib/` and `overlays/`; home-manager modules use native `programs.<name>` options and generated-format helpers rather than hand-rolled `home.file` where a native path exists; platform branching uses one convention.

### Modified Capabilities
<!-- none: this change introduces cleanup invariants; it does not alter an existing spec's requirements -->

## Impact

- Affected code: `overlays/` (delete crossplane + mozilla; migrate contextive, sheets, wumpusMono, bookerly; refactor codex-acp, default; drop the 25 `_:` wrappers), `overlays/default.nix`, `lib/builders/*`, `lib/builders.nix`, `modules/lib/platform.nix`, `modules/home/programs/{zsh,yazi,kubectl,git,git/options}`, `nvfetcher.toml`, `_sources/generated.nix`, `.gitignore`. No `flake.nix`/`flake.lock` change.
- Progressive rollout: the change splits into 3 independently buildable slices (Tier 1 reproducibility/security, Tier 2 dead/duplicated code, Tier 3 native-option/nvfetcher). Each slice ends at a green `nix flake check`.
- Gating signal: `nh darwin build` (verify) MUST pass before `nh darwin switch` (apply) for every slice. Never switch on a red build.
- Impactful actions requiring human checkpoints: running `nvfetcher` to regenerate `_sources/generated.nix` (Tier 3); `nix flake check` after each slice; `nh darwin build` before any `nh darwin switch`; deleting `switch.err` from the tree.
- No external-factual claims: all version pins are provided by `flake.lock`, `nvfetcher` `_sources`, and `vendorHash`, so no `citations.lock` is required.
