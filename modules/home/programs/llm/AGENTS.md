# Agent runtime and skill integration

Read the relevant sections of `docs/repository-reference.md` from the repository
root before changing a harness, hook, renderer, or skill installation path.

- `harnesses/registry.nix` owns harness identity, context locations, skill roots,
  and capabilities. Publish complete entries; do not add private consumer lists.
- `lib/instructions.nix` owns shared decisions and routing. Keep workflow details
  in skills. Work-specific routes and skills are supplied by `sysinit.laurel`.
- `skills/default.nix` discovers shared skills; `skills/render.nix` renders
  metadata and includes resources. Keep skill descriptions scoped and explicit.
- `lib/mcp-routing.nix` owns transport translation. Extending the gateway target
  list changes the auto-approval surface; follow existing authorization scope.
- `gate.nix` owns hook chains, `gate-defaults.nix` owns injected prose, and the
  gate input owns providers. Inspect `gate log tail` when diagnosing decisions.
- The OpenSpec schema is `openspec-schema/`, not the openspec package overlay.
  Its per-file installation is required because discovery skips linked directories.
- Run `checks/skill-catalog.nix` and `checks/harness-instructions.nix` through
  their flake checks when changing metadata, resources, routing, or renderers.
  Use `docs/skill-routing-cases.json` for manual selection checks; static checks
  cannot establish model adherence.
- Review the reference's harness field footguns before adding native settings.
  A parsed configuration is not evidence that a native feature is active.
