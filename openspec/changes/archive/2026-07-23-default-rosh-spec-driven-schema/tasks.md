## 1. Lever 1: XDG user-override install

- [x] 1.1 Add a home-manager module (under `modules/home/programs/llm/`) that installs the in-repo `openspec/schemas/rosh-spec-driven/` to `$XDG_DATA_HOME/openspec/schemas/rosh-spec-driven/` via `xdg.dataFile`, sourced from the flake so it stays a single source of truth
- [x] 1.2 `nix flake check`
- [x] 1.3 `nh darwin build` (no system change)
- [x] 1.4 Adversarial review (`adversarial-review` skill): critics attempt to break Slice 1 against its spec scenarios (fork-resolves-outside-sysinit, XDG-install-missing); revise until no surviving objection or K=4 rounds — done in the 4-round loop (round 3 spec-coherence critic drove the drift-claim fix; XDG path verified against openspec `getGlobalDataDir`)
- [x] 1.5 HUMAN CHECKPOINT: run `nh darwin switch`, then from `/tmp` run `openspec schema which rosh-spec-driven` and confirm `Source: user` — verified: `Source: user`, `/Users/roshan/.local/share/openspec/schemas/rosh-spec-driven`

## 2. Lever 2: patch the default constant

- [x] 2.1 Add a `postPatch` to `overlays/openspec.nix` that rewrites all six default-schema sites in the built `dist/` (`openspec-root.js` `DEFAULT_OPENSPEC_SCHEMA`, `init.js` `DEFAULT_SCHEMA`, `commands/workflow/shared.js` `DEFAULT_SCHEMA`, `utils/change-utils.js` `DEFAULT_SCHEMA`, `planning-home.js` `REPO_DEFAULT_SCHEMA`, and the inline `defaultSchema: 'spec-driven'` in `root-selection.js`); use `substituteInPlace ... --replace-fail` (or a match-count guard) so a missed site fails the build
- [x] 2.2 Add a hermetic behavioral test as a `nix flake check` (not an `installCheckPhase`, to keep the openspec derivation cache clean): `HOME`/`XDG_DATA_HOME` in tmp, copy the in-repo schema into the tmp XDG dir, `openspec new change probe` with no network, assert the written `config.yaml` names `rosh-spec-driven` (catches a new or moved default site that `--replace-fail` misses)
- [x] 2.3 Record the patch in `openspec/schemas/rosh-spec-driven/CHANGES.md` with the upstream files it overrides
- [x] 2.4 `nix flake check`; `nh darwin build` (no system change)
- [x] 2.5 Adversarial review (`adversarial-review` skill): critics attempt to break Slice 2 against its spec scenarios (fresh-init-picks-the-fork, patched-default-with-no-resolvable-schema, removed-known-site-fails-the-build, new-controlling-site-caught-by-the-behavioral-test); revise until no surviving objection or K=4 rounds — done in the 4-round loop (rounds 1-2 drove the all-six-sites + fail-loud fixes; round 3 build-sandbox critic empirically confirmed the hermetic check runs)
- [x] 2.6 HUMAN CHECKPOINT: run `nh darwin switch`, then in an empty temp dir run `openspec new change probe`, confirm `schema: rosh-spec-driven` in its config, then delete the probe

## 3. Sync script and docs

- [x] 3.1 Confirm `hack/sync-openspec-schema.sh` still detects real template drift after the patch; if it needs a note that the `dist/` patch is covered by the Slice 2.2 assertion (not by this script), add it
- [x] 3.2 `task openspec:sync` returns clean; `task fmt:sh:check` passes
- [x] 3.3 Update `AGENTS.md` (state the machine-wide default and the shared-repo practice: pin `schema: spec-driven` or `openspec init --schema spec-driven`) and `modules/home/programs/llm/lib/instructions.nix`
- [x] 3.4 Adversarial review (`adversarial-review` skill): critics attempt to break Slice 3 against its spec scenarios (undocumented-patch-caught, shared-repo-practice-is-documented, teammate-on-a-leaked-config-gets-an-explicit-error); revise until no surviving objection or K=4 rounds

## 4. Rollout

- [x] 4.1 Confirm the gate sequence in `design.md` (Rollout & Gating) was followed for every slice
- [x] 4.2 Kill switch verified: reverting the overlay `postPatch` restores the upstream default without touching Lever 1
