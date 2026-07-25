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
- [x] 2.8 Apply: no-op. Slice 2 closure is byte-identical to the currently-active system (DIFF 0 bytes), so `nh darwin switch` would re-activate the same store path. Skipped.
- [x] 2.9 Confirm: zsh and nushell PATH now both derive from `getAllPaths` (identical by construction); both nixos hosts and the darwin host evaluate.

## 3. Slice 3 — native options and nvfetcher (Tier 3)

- [ ] 3.1-3.3 DROPPED — nvfetcher migration. Inspection shows it is wrong for these pins: `wumpusMono` tracks a specific commit (not a release), `bookerly` is a raw-URL font with no version/tag, and nvfetcher tracks releases — migrating would auto-update the intentional pins (violates the no-auto-update prohibition). `contextive` is a 4-platform .NET single-file derivation (complex, marginal gain); `sheets` gain is one hash line. Left as hand-pinned.
- [ ] 3.4 DROPPED — yazi native module. The real `yazi/default.nix` is `home.packages = [ yazi ]` plus a clean `xdg.configFile."yazi" = { source = ./yazi; recursive = true; }` directory symlink, not hand-rolled plugin mapping. Decomposing a hand-maintained config dir into `programs.yazi` attrsets is more churn, not less.
- [x] 3.5 Native `programs.git.attributes = [ "* merge=mergiraf" ]` in `git/default.nix`; `kubectl` `kuberc` generated via `pkgs.formats.yaml` from an attrset (matches `ast-grep.nix`). Generated YAML verified semantically equivalent to the old heredoc.
- [x] 3.6 Moved the ~80-line seshy/wezterm Bash block to `zsh/integrations/seshy-wezterm.zsh`, read via `stripHeaders` (matches the file's other chunks). Generated zsh init still contains the helper functions; zero closure change.
- [ ] 3.7 DEFERRED — Darwin overlay helpers. Marginal: the stdenv sweep (3.8) already modernized `opa`/`kvazaar`/`codex-acp`; a shared helper adds import boilerplate for 1-2 uses each. Flagged to owner.
- [x] 3.8 (partial) Migrated all 20 `stdenv.isDarwin`/`isLinux` uses to `stdenv.hostPlatform.*` across 10 files (zero remain outside `templates/`). DEFERRED the `with lib;` removal (2 files, pure nit) and the `ssh.*` namespace move (coordination cost across options/hosts/ssh for a cosmetic rename).
- [x] 3.9 Adversarial review: primary rubric risks (behavior change; kuberc/gitattributes equivalence) addressed by the verify evidence below (build green, kuberc YAML equivalent, zsh functions preserved, stdenv sweep zero closure change). No surviving objection. Note: subagent critics were unreliable this session (repeated hallucinated reads), so verification rests on direct evals.
- [x] 3.10 Verify: `nh darwin build` green; closure diff is only the intended git/kubectl file relocations (+7/-7 paths, -72 bytes); generated kuberc YAML equivalent; `grep` finds no `stdenv.isDarwin`/`isLinux` outside `templates/`.
- [x] 3.11 Apply: `nh darwin switch` (activated). Closure diff: git/kubectl config relocations only.
- [x] 3.12 Confirm: `~/.kube/kuberc` is valid YAML; `git check-attr merge -- foo.txt` reports `mergiraf`; `wezcopy`/`s` defined in interactive zsh.
