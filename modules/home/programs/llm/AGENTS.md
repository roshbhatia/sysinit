# Agent runtime and skill integration

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
- Run `checks/agents/skill-catalog.nix` and `checks/agents/harness-instructions.nix` through
  their flake checks when changing metadata, resources, routing, or renderers.
  Use `checks/agents/skill-routing-cases.json` for manual selection checks; static checks
  cannot establish model adherence.
- Verify native harness settings through the affected behavior as well as parsing.
