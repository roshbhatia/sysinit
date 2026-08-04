## Why

The custom schema is installed through a Home Manager module from a distant
project path. The OpenSpec package already owns its built-in schemas, so the
custom schema should use the same package-owned pattern.

## What Changes

- Move the OpenSpec overlay and its custom schema into one owned directory.
- Install `rosh-spec-driven` inside the OpenSpec package.
- Remove the separate XDG schema installation module.
- Make checks validate the installed schema instead of copying repository files.

The existing package schema at `${pkgs.openspec}/lib/openspec/schemas/spec-driven`
is the pattern this change extends.

### Non-goals

- Changing the schema instructions or templates.
- Changing the patched default schema name.
- Distributing the custom schema outside this flake.

## Behavior

Must do:
- `openspec schema which rosh-spec-driven` reports `Source: package` outside this repository, decided by the default-schema check.
- The OpenSpec checks use the installed package without a copied project schema, decided by source inspection and `nix flake check`.
- The schema source uses no parent-directory traversal, decided by `rg 'schemaSrc = \.\./' overlays modules checks` returning no match.

Must still hold:
- A bare `openspec new change` selects `rosh-spec-driven`, decided by the default-schema check.
- A scaffold from the shipped templates passes the deterministic rubric, decided by the template-conformance check.
- The upstream drift script compares the custom schema with `spec-driven`, decided by `./hack/sync-openspec-schema.sh` reaching its expected divergence report.

Human-owned decision:
- The owner confirms that package resolution is the intended global installation boundary.

## Impact

Modified code:
- `overlays/openspec.nix`
- `overlays/default.nix`
- `modules/home/programs/llm/openspec-schema.nix`
- `modules/home/programs/llm/default.nix`
- `openspec/schemas/rosh-spec-driven/`
- `checks/openspec-default-schema.nix`
- `checks/schema-templates-conform.nix`
- `hack/sync-openspec-schema.sh`

Dependencies: none.

Impactful and irreversible actions:
- `git push` publishes the change.

Gating signal: `nix flake check`, then a package build and an external-directory schema probe.
