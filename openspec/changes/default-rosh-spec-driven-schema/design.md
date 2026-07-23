## Context

`rosh-spec-driven` is a project-local fork at `openspec/schemas/rosh-spec-driven/`. The openspec CLI resolves schemas in this order: project `openspec/schemas/`, then XDG user override `$XDG_DATA_HOME/openspec/schemas/`, then package built-in. The default schema name is hardcoded in the packaged CLI (`dist/core/openspec-root.js` `DEFAULT_OPENSPEC_SCHEMA`, plus `dist/core/init.js` and `dist/core/root-selection.js`). There is no global config key for a default schema. `openspec/config.yaml` already pins `schema: rosh-spec-driven` for this repo.

## Goals / Non-Goals

**Goals:**

- `rosh-spec-driven` resolves in every project on the machine.
- A bare `openspec init` or `openspec new change` selects `rosh-spec-driven` with no flag.
- One source of truth for the schema files: the in-repo directory.
- Overlay drift detection stays meaningful after the patch.

**Non-Goals:**

- Distributing the schema to other machines or a registry.
- Changing the schema's authoring rules.

## Decisions

- Decision: Install via `xdg.dataFile` sourced from the in-repo schema directory, treated as a rebuild-gated store snapshot.
  - Note on drift: `xdg.dataFile.source` from a flake copies the files into `/nix/store` and links the XDG path at that snapshot, so a working-tree edit is visible only after the next `nh darwin switch`. This is the normal nix-managed-file behavior; the spec claims no between-rebuild zero-drift, so there is no self-contradiction with rejecting a live symlink.
  - Alternative rejected: `config.lib.file.mkOutOfStoreSymlink` to the absolute repo path. Rejected because it makes resolution depend on the repo staying at a fixed absolute path and breaks reproducibility; the rebuild-gated snapshot is preferred.
  - Alternative rejected: `openspec schema fork` at activation time. Rejected because it is imperative, not reproducible, and writes mutable state outside Nix control.

- Decision: Patch every default-schema site in the built `dist/` via `overlays/openspec.nix` `postPatch`, failing the build on a missed site.
  - Alternative rejected: set a global config key. Rejected because openspec 1.6.0 has no default-schema config key; the sites are the only lever.
  - Alternative rejected: patch only the named constants (`DEFAULT_OPENSPEC_SCHEMA`, `DEFAULT_SCHEMA`). Rejected because `openspec new change` reads `root.defaultSchema` from the inline `defaultSchema: 'spec-driven'` object-literal in `root-selection.js`, which is not a named constant; missing it leaves the behavior unchanged.
  - Alternative rejected: a non-failing `sed`. Rejected because a silent no-op on an upstream rename reverts the default machine-wide with no signal; the patch uses `--replace-fail`.
  - Alternative rejected: a static re-read of the six `dist/` sites as the health check. Rejected because it is blind to a newly added or moved controlling site; the check is instead a hermetic behavioral test (`HOME`/`XDG_DATA_HOME` in tmp, copy the schema in, `openspec new change probe`, assert the written config) that exercises the real resolution path with no network.
  - Alternative rejected: run that behavioral test as an `installCheckPhase` inside the openspec derivation. Rejected because sourcing the schema from the repo would pull the whole repo tree into the openspec derivation inputs (via `inputs.self`) and defeat its cachix caching; it runs as a separate `nix flake check` instead.
  - Alternative rejected: shell wrapper that injects `--schema rosh-spec-driven`. Rejected because it does not cover `openspec init` config generation and breaks any explicit `--schema` a user passes.

- Decision: No commit-time guard. Document the shared-repo practice (pin `spec-driven`) in `AGENTS.md` and rely on the explicit "schema not found" error a teammate gets.
  - Alternative rejected: an absolute Nix-managed dispatcher hook that blocks the leak and execs per-repo hooks. Rejected because `core.hooksPath` is a single slot (a relative value never fires in a foreign repo; an absolute value must re-implement lefthook/husky discovery to avoid disabling other repos' hooks). That is the highest-complexity, lowest-value piece for a single user, and the failure it prevents is already an explicit error, not silent misbehavior.
  - Alternative rejected: warn-only guard. Rejected because the harm falls on the teammate, not the author, so a warning the author can ignore prevents nothing.
  - Alternative rejected: distribute the schema so any repo resolves it. Rejected: distribution is an explicit Non-goal for this change.

- Decision: Lever 1 (XDG install) must land and be verified before Lever 2 (default patch).
  - Alternative rejected: ship both in one switch with no ordering. Rejected because a patched default that cannot resolve produces a hard error on every fresh init.

## Rollout & Gating

Sequence, one slice per gate:

1. Slice 1, Lever 1 (XDG install): edit the home-manager module, then `nix flake check`, then `nh darwin build`, then user spot-check (`openspec schema which rosh-spec-driven` from `/tmp` reports `Source: user`), then `nh darwin switch`.
2. Slice 2, Lever 2 (overlay patch): edit `overlays/openspec.nix` and `CHANGES.md`, then `nix flake check`, then `nh darwin build`, then user spot-check (`openspec new change probe` in an empty temp dir writes `schema: rosh-spec-driven`; delete the probe), then `nh darwin switch`.
3. Slice 3, sync-script and docs: edit `hack/sync-openspec-schema.sh` and docs, then `task openspec:sync` returns clean, then `nix flake check`.

Kill switch: revert the overlay `postPatch` (Lever 2 only) to restore the upstream default without touching Lever 1. The XDG install is additive and safe to keep.

## Risks / Trade-offs

- Risk: the overlay patch targets a site that upstream renames or minifies on a version bump. → Mitigation: the patch fails the build on a missed site (`--replace-fail` or match-count guard), and a `dist/` assertion checks the effective default; `hack/sync-openspec-schema.sh` alone cannot catch this because it never inspects `dist/*.js`. Maps to the Slice 2 human-verification checkpoint.
- Risk: `$XDG_DATA_HOME` unset on a fresh machine. → Mitigation: the default `~/.local/share` matches openspec's `getGlobalDataDir`; verify in the Slice 1 spot-check.
- Risk: a foreign project that expected upstream `spec-driven` now errors on a missing schema at read time. → Mitigation: this is the intended BREAKING behavior; the error is explicit and names available schemas.
- Risk: bare `init` writes the fork name into a shared repo's committed config, breaking teammates who cannot resolve it (write-time leak). → Mitigation: the shared-repo practice (pin `spec-driven`) is documented in `AGENTS.md`, and the teammate's failure is an explicit "schema not found" error, not silent misbehavior. A commit-time guard was considered and dropped as not worth the cost. Maps to a Slice 3 documentation task.

## Adversarial Review

Rubric: the spec scenarios (including the negative scenarios for a missing XDG install and an unresolvable patched default), the `Decisions` and their rejected alternatives, the `Rollout & Gating` gate sequence, and the proposal `Non-goals`. Each slice is cleared by the `adversarial-review` loop before it is marked done: independent critics attempt to break the slice with a concrete failing scenario that names a violated rubric item, the author revises against surviving objections, and the loop repeats until no objection survives or K=4 rounds. Executor per the `adversarial-review` skill: in-process teammate critics under Claude Code, subagents elsewhere.
