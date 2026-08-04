## Context

`modules/home/programs/llm/openspec-schema.nix` installs each schema leaf through
`xdg.dataFile`. It reaches the source through four parent directories. The
OpenSpec derivation already installs upstream schemas under its package output.

The overlay will become a directory because it owns the custom schema asset.
This follows the repository rule that an owner with assets keeps `default.nix`
beside those assets.

## Goals / Non-Goals

Goals:
- Make the OpenSpec package the only installed schema owner.
- Keep the custom schema source beside its package definition.
- Test the exact schema files that users run.

Non-Goals:
- Change schema policy.
- Change project OpenSpec artifacts.

## Decisions

### D1. Install the schema in the OpenSpec package output

The derivation copies the custom schema beside the upstream package schemas.
OpenSpec then resolves it through its existing package source.

- Alternative rejected: retain the XDG user override. It creates a second installation mechanism and can shadow the packaged files.

### D2. Make the overlay a directory

`overlays/openspec/default.nix` can refer to `./rosh-spec-driven` directly.

- Alternative rejected: keep the schema under the project `openspec/` directory. That directory is for project changes, and it shadows the global schema during tests.

### D3. Validate the installed package

Checks resolve templates from `${pkgs.openspec}` and use an empty XDG root.

- Alternative rejected: pass the source path into each check. That tests authoring inputs instead of the installed result.

## Rollout & Gating

Phase 1 moves the source and packages it. `nix flake check` must pass. Phase 2
builds the package and confirms package resolution from a temporary directory.

The kill switch restores the prior overlay file and XDG module before a
downstream configuration updates this flake.

## Risks / Trade-offs

- Package source changes can invalidate the OpenSpec derivation cache. -> The custom schema is small and belongs in that derivation.
- A stale XDG link can keep shadowing the package after activation. -> The external-directory probe requires `Source: package`.
- An upstream layout change can break the copy target. -> The behavioral check resolves the schema through the CLI.

## Migration Plan

1. Move the overlay and schema into one directory.
2. Update checks and the drift script.
3. Run `nix flake check` and build `pkgs.openspec`.
4. Confirm the built schema reports `Source: package` outside the repository.

Rollback restores the old module and overlay layout before downstream rollout.

## Adversarial Review

Review this change against the proposal Behavior criteria, Decisions, rollout
gates, and Non-goals. Run `specutil check` and the `adversarial-review` skill.

## Open Questions

None.
