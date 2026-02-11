''
  ---
  name: nix-development
  description: Use when writing or modifying Nix code, creating modules, updating flake inputs, or working with the sysinit configuration structure
  ---

  # Nix Development

  ## Overview

  All system configuration in this repo is expressed as Nix. Modules follow a strict two-file pattern and are formatted with `nixfmt`.

  ## Formatting

  - Formatter: `nixfmt --width=100`
  - Run: `task fmt:nix` (format) or `task fmt:nix:check` (verify)
  - Validate flake: `task nix:validate`

  ## Module Pattern

  Every module uses a two-file structure:

  ```nix
  # default.nix (entry point - imports only)
  { config, lib, ... }: {
    imports = [ ./name.nix ];
  }

  # name.nix (implementation)
  { config, lib, values, ... }: {
    # Implementation here
  }
  ```

  - `default.nix` is the entry point, contains only imports
  - `name.nix` contains the actual implementation
  - The `values` parameter provides user-configurable settings

  ## Naming Conventions

  - Variables: `camelCase`
  - File names: `snake_case`
  - Options: use `mkOption { type = types.str; description = "..."; }`

  ## Imports and Expressions

  - Top of file: `{ lib }: with lib;`
  - Use `with lib;` for convenience within module scope
  - Group related options together
  - Use `//` for attribute set merging

  ## Type Schemas

  - Define type schemas in `modules/shared/lib/schema.nix`
  - Use `mkOption` with explicit types and descriptions
  - Use `types.nullOr` for optional values
  - Use `types.listOf types.str` for string lists
  - Use `types.attrsOf` for attribute sets
  - Use `types.submodule` for nested option groups

  ## Error Handling

  - Use `assert` for preconditions
  - Use `throw` for unrecoverable errors
  - Use `lib.optionalAttrs` for conditional attribute inclusion

  ## Key Files

  | File | Purpose |
  |------|---------|
  | `flake.nix` | Input definitions and output routing |
  | `flake/outputs.nix` | Output builders and system configs |
  | `flake/hosts.nix` | Host definitions (lv426, arrakis, etc.) |
  | `modules/shared/lib/schema.nix` | Type schemas and validation |
  | `modules/darwin/default.nix` | macOS system configuration |
  | `modules/nixos/default.nix` | NixOS system configuration |
  | `modules/home/default.nix` | User-level home-manager configuration |

  ## Build and Test

  ```bash
  task nix:build:lv426     # Build macOS specifically
  task nix:build:arrakis   # Build NixOS specifically
  task nix:build:all       # Build all configurations
  task nix:build:work      # Dry-run work config
  ```

  ## Common Mistakes

  - Forgetting `...` in function arguments (breaks extensibility)
  - Using `let ... in` where `with` would be cleaner
  - Not running `task nix:build` before committing
  - Hardcoding paths instead of using `values.config.root`
  - Creating deeply nested option trees instead of flat, composable ones
''
