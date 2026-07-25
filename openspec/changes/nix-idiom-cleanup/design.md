## Context

This change acts on an idiom audit of the flake. The current patterns being extended:

- Overlays are composed in `overlays/default.nix` via `lib.composeManyExtensions`; nvfetcher-backed overlays (`go-enum.nix`, `crush.nix`, `localias.nix`) already read `final.nvfetcherSources` from `overlays/nvfetcher-sources.nix` and `_sources/generated.nix`. The migration work parallels that established pattern; no new fetch mechanism is introduced.
- `overlays/crossplane.nix:5-8` pins nixpkgs rev `882842d2` to hold `crossplane-cli` at 1.17.1. Eval shows the current `nixpkgs` input ships `crossplane-cli` 2.4.0, so the overlay is load-bearing, not redundant. The owner accepts the bump to 2.4.0 (crossplane v2), so the fix deletes the overlay and uses `pkgs.crossplane-cli`, which `modules/home/packages.nix:147` already references.
- `lib/builders/darwin.nix` and `lib/builders/nixos.nix` already share `commonArgs` from `lib/builders.nix:47`; the duplication is only in the per-builder `modules` list. A `mkBase` helper extends the same builder structure.
- `modules/lib/paths.nix` `getAllPaths` is already the source of truth consumed by `nushell.nix:13`. Wiring zsh to it closes a known two-place edit, not a new abstraction.
- Native home-manager options (`programs.fastfetch`, `programs.oh-my-posh`) and `pkgs.formats`/`lib.generators.toYAML` (`ast-grep.nix`) are already the repo baseline. Yazi, git-attributes, and kubectl are the outliers being brought to that baseline.

No new architectural pattern is introduced. Every edit moves a straggler onto an existing repo convention.

## Goals / Non-Goals

**Goals:**
- Close the one reproducibility hole (out-of-lock nixpkgs for `crossplane-cli`).
- Remove dead code, dead args, and duplicated sources of truth in `lib/` and `overlays/`.
- Move home-manager module stragglers onto native options and generated-format helpers.
- Keep generated output equivalent: the switch closure MUST NOT change behavior.

**Non-Goals:**
- No flake-parts / flake-utils adoption.
- No tool runtime-behavior change.
- No `flake.lock` changes; `crossplane-cli` moves onto the existing `nixpkgs` input.
- No change to `NODE_TLS_REJECT_UNAUTHORIZED` (stays global by owner decision; it exists for Cursor).
- No git history rewrite for `switch.err`.

## Decisions

- Decision: Delete `overlays/crossplane.nix` and use `pkgs.crossplane-cli` 2.4.0 from the main `nixpkgs` input, accepting the 1.17.1 -> 2.4.0 bump.
  - Rationale: the overlay pins 1.17.1 via an out-of-lock `fetchTarball`; upstream is on 2.4.0. Removing the impurity means either re-pinning 1.17.1 or moving to 2.4.0. The owner is ready for crossplane v2, so upstream is the simplest reproducible source.
  - Alternative rejected: keep 1.17.1 via a dedicated pinned nixpkgs flake input at rev `882842d2`. Rejected by owner decision: they accept v2, so a second full nixpkgs closure for one CLI is not worth it.
  - Alternative rejected: keep 1.17.1 via nvfetcher (buildGoModule from source). Rejected for the same reason plus the added vendorHash/build maintenance.
  - Alternative rejected: keep `fetchTarball` but pin by narHash. Rejected because it still bypasses `flake.lock` and breaks pure eval.

- Decision: Delete `modules/lib/platform.nix` entirely; move the two legitimate brew helpers (`getBrewPrefix`, `getBrewArchitecture`) to where they are consumed, corrected to `hasSuffix`/`lib.systems`.
  - Rationale: the OS predicates are broken (`hasPrefix "darwin"` is false for `aarch64-darwin`) and have zero live consumers, so the file is dead weight.
  - Alternative rejected: fix the predicates in place and keep the file. Rejected because nothing imports it; keeping it preserves unused surface that will drift again.

- Decision: Extract one `mkBase { ... }` helper returning the shared module list, consumed by both builders.
  - Rationale: `darwin.nix` and `nixos.nix` repeat the pkgs/username/theme/stylix/home-manager/documentation wiring verbatim.
  - Alternative rejected: adopt flake-parts to supply the plumbing. Rejected per the proposal Non-goals; a local helper removes the duplication without a framework migration.

- Decision: Drop the `_:` overlay wrapper; pass `inputs` to `overlays/inputs.nix` via a `let` closure in `overlays/default.nix`, which already receives `inputs`.
  - Rationale: 24 of 25 overlays ignore the first arg; only `inputs.nix` needs `inputs`.
  - Alternative rejected: keep the uniform `_:` signature for symmetry. Rejected because symmetry with a dead arg is noise, not consistency.

- Decision: Migrate `contextive`, `sheets`, `wumpusMono`, `bookerly` to `nvfetcher.toml`; regenerate `_sources/generated.nix` with `nvfetcher`.
  - Rationale: they hand-pin hashes that nvfetcher already automates for sibling packages (`crush`, `localias`).
  - Alternative rejected: leave the hand-pinned hashes. Rejected because they drift silently and duplicate the nvfetcher update path.

- Decision: Extract `overrideOnDarwin` and `useLldOnDarwin` overlay helpers.
  - Rationale: the `if stdenv.isDarwin then X.overrideAttrs else X` guard and the ld64.lld RUSTFLAGS block repeat ~10 times, verbatim in two files.
  - Alternative rejected: leave the duplication with its explanatory comments. Rejected because the helper can carry the comment once and the guards stay in lockstep.

## Rollout & Gating

Ship in 3 sequenced slices. Each slice is one reviewable unit and MUST clear its gate before the next starts.

1. Slice 1 (Tier 1: reproducibility): delete crossplane overlay (accepts crossplane-cli 2.4.0), `switch.err` removal + gitignore.
   - Gate: `nix flake check` green, then `nh darwin build` green (confirm `crossplane-cli` resolves at 2.4.0), then user spot-check of the built closure.
2. Slice 2 (Tier 2: dead + duplicated code): platform.nix, mkBase, dead args, zsh PATH, overlay `_:` + mozilla.nix.
   - Gate: `nix flake check` green; `nh darwin build` closure diff shows no unintended store-path changes; user spot-check.
3. Slice 3 (Tier 3: native options + nvfetcher): yazi, git-attributes, kubectl, zsh externalize, nvfetcher migration, `stdenv`/`with lib;` nits.
   - Gate: run `nvfetcher` (regenerates `_sources`), then `nix flake check` green, then `nh darwin build`, then diff the generated `yazi.toml`/`kuberc`/git-attributes against the pre-change output, then user spot-check.

Default gate sequence per slice: edit → `nix flake check` → `nh darwin build` (no system change) → user spot-check → `nh darwin switch`. The kill switch is git: each slice is a separate revertible commit, and no `nh darwin switch` runs until the build is green.

## Risks / Trade-offs

- [nvfetcher regeneration changes a source hash unexpectedly] → Run `nvfetcher` in isolation, review the `_sources/generated.nix` diff before building; human checkpoint in tasks.md.
- [yazi native module emits a different `yazi.toml` than the hand-rolled file] → Diff generated config before/after; if plugins do not resolve, revert Slice 3's yazi task only.
- [mkBase extraction drops a module arg and silently changes a build] → Compare `nh darwin build` store paths before/after Slice 2; human checkpoint.
- [crossplane v2 CLI breaks an existing 1.x workflow] → Owner accepted the bump; verify `crossplane --version` reports 2.4.0 and smoke-test the CLI paths in use before `nh darwin switch`. Rollback is `git revert` of the slice (restores the 1.17.1 overlay).

## Migration Plan

Per slice, in order:

1. Verify current state: `nix flake check` green on `main` before editing.
2. Apply the slice edits.
3. Verify: `nix flake check`.
4. Verify: `nh darwin build` (no system change).
5. For Slice 1: confirm `nh darwin build` resolves `crossplane-cli` at 2.4.0 after the overlay is deleted, and smoke-test the crossplane CLI paths in use (v1 -> v2 is breaking).
6. For Slice 3 only: before step 3, run `nvfetcher` and review the `_sources/generated.nix` diff (impactful: mutates a tracked generated file); confirm the diff is only the 4 migrated packages.
7. Confirm: user spot-checks the build output and generated config diffs.
8. Apply: `nh darwin switch` (impactful: mutates system state) only after step 7 confirms.
9. Rollback: `git revert` the slice commit and re-run `nh darwin switch`, or `darwin-rebuild --rollback`.

## Adversarial Review

Rubric: the spec scenarios in both capability specs (including every negative scenario), the `Decisions` above (each with its rejected alternative), the `Rollout & Gating` gates, and the proposal `Non-goals`. Each slice is cleared by the adversarial-review loop before its tasks.md checkbox is marked done: independent critics attempt to break the slice with a concrete failing scenario that names a violated rubric item, the author revises against surviving objections, and the loop repeats until no objection survives or K=4 rounds. Executor per the `adversarial-review` skill: in-process teammate critics under Claude Code, subagents elsewhere. Per-slice checkmarks live in `tasks.md`.

## Open Questions

- Resolved: `NODE_TLS_REJECT_UNAUTHORIZED = 0` exists for Cursor (added by commit `64d987568`). It stays global by owner decision; not touched by this change.
- Resolved: the crossplane overlay pins 1.17.1; current nixpkgs is on 2.4.0 (eval-verified). The initial "versions match" reading was a contaminated eval (overlay-applied pkgs compared against itself). Owner accepts the bump to 2.4.0, so the overlay is deleted and `pkgs.crossplane-cli` (2.4.0) is used.
