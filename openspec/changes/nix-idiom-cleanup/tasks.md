## 1. Slice 1 — reproducibility (Tier 1)

- [x] 1.1 Delete `overlays/crossplane.nix`, remove its import from `overlays/default.nix`, and drop the `crossplane` cacheAttrs entry in `flake.nix`; `crossplane-cli` now resolves from upstream nixpkgs at 2.4.0 (owner-accepted v1->v2 bump). `modules/home/packages.nix:147` still references `crossplane-cli`
- [x] 1.2 `git rm --cached switch.err`, delete the file, add a `switch.err` pattern to `.gitignore`
- [x] 1.3 Adversarial review (`adversarial-review` skill): round 1 surfaced the crossplane version-bump defect (via verify); revised artifacts to record the owner-accepted 1.17.1->2.4.0 bump; no surviving objection (correctness clean, ops refuted as stale read, cache clean)
- [x] 1.4 Verify: `nix flake check` green; `nh darwin build` green (exit 0), `crossplane-cli` resolves at 2.4.0 in the host closure; `git ls-files switch.err` empty
- [x] 1.5 Apply: `nh darwin switch` (activated successfully)
- [x] 1.6 Confirm: `crossplane version` reports Client Version v2.4.0; switch.err absent and ignored. Owner to smoke-test v2 CLI paths in use.

## 2. Slice 2 — dead and duplicated code (Tier 2)

- [x] 2.1 Deleted `modules/lib/platform.nix` (dead + broken predicates, zero consumers); dropped `platform`/`system` from `modules/lib/default.nix`. `getBrewPrefix`/`getBrewArchitecture` were also unused, so dropped with the file.
- [ ] 2.2 DEFERRED — mkBase. Inspection shows the genuinely-identical shared surface is only ~3 tiny attrsets (username, theme optionalAttrs, documentation.enable); home-manager/stylix modules differ by platform namespace and cannot merge. Payoff (~6 lines) does not justify indirection touching both platforms. Flagged to owner.
- [x] 2.3 Removed the dead `customUtils` specialArg (`lib/builders/nixos.nix`). Kept the `lib/builders.nix` re-export (load-bearing: `flake.nix` destructures `builders.mkPkgs`). Left `_system` as the idiomatic unused-arg marker in `pkgs.nix`.
- [x] 2.4 Rewrote `zsh/default.nix` PATH block to call `getAllPaths` from `modules/lib/paths.nix` (matches `nushell.nix`). Verified the inline list was byte-identical to the helper.
- [x] 2.5 Dropped the `_:` wrapper across 23 overlay files; deleted no-op `overlays/mozilla.nix`; updated `overlays/default.nix` call sites to bare `(import ./x.nix)`. `inputs.nix` keeps its live `{ inherit inputs; }` arg (not dead), so no closure needed.
- [x] 2.6 Adversarial review: primary rubric risk (behavior change) refuted by the decisive verify evidence below (byte-identical darwin output + clean nixos eval); no surviving objection.
- [x] 2.7 Verify: `nh darwin build` DIFF 0 bytes (PATHS 1256->1256, +0/-0) — byte-identical output; both nixos hosts (arrakis, nostromo) eval to valid drvPaths; `grep` finds no `customUtils` and no standalone `_:` in overlays.
- [ ] 2.8 Apply: `nh darwin switch`
- [ ] 2.9 Confirm: user spot-checks; zsh and nushell PATH match; both builders still evaluate

## 3. Slice 3 — native options and nvfetcher (Tier 3)

- [ ] 3.1 Add `contextive`, `sheets`, `wumpusMono`, `bookerly` entries to `nvfetcher.toml` (follows the `crush`/`localias` multi-asset pattern)
- [ ] 3.2 Verify: run `nvfetcher`, then review the `_sources/generated.nix` diff — confirm only the 4 new packages change (impactful: mutates a tracked generated file)
- [ ] 3.3 Rewrite the 4 overlay files to read from `final.nvfetcherSources`; remove their inline hashes
- [ ] 3.4 Switch `modules/home/programs/yazi/default.nix` to native `programs.yazi` (`settings`, `plugins`)
- [ ] 3.5 Use native `programs.git.attributes` in `git/default.nix`; generate `kubectl` `kuberc` via `pkgs.formats.yaml` (matches `ast-grep.nix`)
- [ ] 3.6 Move the inline seshy/wezterm Bash block from `zsh/default.nix` to a sibling `.zsh` file read via `stripHeaders` (matches the file's `core/init.zsh` pattern)
- [ ] 3.7 Extract `overrideOnDarwin` / `useLldOnDarwin` overlay helpers; replace the ~10 duplicated Darwin guards including `codex-acp.nix` and the inline blocks in `overlays/default.nix`
- [ ] 3.8 Migrate 20 `stdenv.isDarwin`/`isLinux` uses to `stdenv.hostPlatform.*`; replace 3 `with lib;` with `inherit (lib) ...`; move `ssh.*` options out of `sysinit.git` into an ssh namespace
- [ ] 3.9 Adversarial review (`adversarial-review` skill): critics attempt to break Slice 3 against `specs/nix-config-idiom/spec.md` native-option, nvfetcher, and platform-convention scenarios; revise until no surviving objection or K=4 rounds
- [ ] 3.10 Verify: `nix flake check` green; `nh darwin build` green; diff generated `yazi.toml`/`kuberc`/git-attributes against pre-change output; `grep -r stdenv.isDarwin` and `with lib;` (outside `templates/`) return nothing
- [ ] 3.11 Apply: `nh darwin switch`
- [ ] 3.12 Confirm: user spot-checks yazi, git, and kubectl behavior; the 4 migrated packages build from nvfetcher sources
