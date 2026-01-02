# AGENTS.md

Nix-flakes configuration for macOS (Apple Silicon) and NixOS. Reproducible system setup via nix-darwin + home-manager.

## Essential Commands

### Build/Test/Apply
```bash
task nix:build                # Test current system config (default: lv426/macOS)
task nix:build:lv426          # Test macOS config specifically
task nix:build:arrakis        # Test NixOS config specifically
task nix:refresh              # Apply current config to system
task nix:refresh:lv426        # Apply macOS config
task nix:refresh:arrakis      # Apply NixOS config
```

### Format/Lint
```bash
task fmt                      # Format all (Nix, Lua, Shell)
task fmt:nix                  # Format Nix files only
task fmt:lua                  # Format Lua files only
task fmt:lua:lint             # Lint Lua with LSP diagnostics
task fmt:sh                   # Format shell scripts
task fmt:all:check            # Check all formatting without changes
```

### Validation
```bash
task nix:validate             # Validate flake configuration
task nix:build                # Build-time validation
```

### Maintenance
```bash
task nix:update               # Update flake inputs and commit
task nix:clean                # Cleanup old generations
task docs:values              # Generate values.nix documentation
```

## Code Style Guidelines

### Nix
- **Formatting**: `nixfmt --width=100`
- **Structure**: Use `default.nix` for entry points, `name.nix` for implementations
- **Imports**: `{ lib }: with lib;` at top, then `with lib;` for convenience
- **Types**: Define schemas in `modules/shared/lib/values/default.nix`
- **Options**: Use `mkOption { type = types.str; description = "..."; }`
- **Naming**: `camelCase` for variables, `snake_case` for file names
- **Error Handling**: Use `assert` for preconditions, `throw` for errors
- **Organization**: Group related options, use `//` for merging

### Lua (Neovim/WezTerm/Hammerspoon)
- **Formatting**: `.stylua.toml` (column_width=100, indent_width=2, spaces)
- **Structure**: `local M = {}` pattern for modules
- **Naming**: `snake_case` for variables/functions, `PascalCase` for modules
- **Imports**: `local module = require("path")` or `local var = require("path").var`
- **Error Handling**: Use `pcall()` for optional operations, explicit error messages
- **Tables**: Use `{}` for objects, `[]` for arrays, consistent comma placement
- **Functions**: Prefer `function()` over `() ->` for clarity
- **Location**: `modules/home/configurations/{app}/lua/sysinit/`

### Shell Scripts
- **Shebang**: `#!/usr/bin/env bash`
- **Safety**: `set -euo pipefail` always first
- **Logging**: Source `{{.LOGLIB_PATH}}`, use `log_info`, `log_success`, `log_error`, `log_warn`
- **Formatting**: `shfmt -i 2 -ci -sr -s -w`
- **Executability**: All `.sh` files must be executable (`task sh:chmod`)
- **Error Handling**: Check command success, provide meaningful error messages
- **Variables**: Use `local` in functions, quote all variables

### General Rules
- **No Emojis**: Strictly enforced in all code
- **DRY Principle**: Extract repeated patterns to shared utilities
- **Documentation**: Use comments for complex logic, maintain schema descriptions
- **Testing**: Run `task nix:build` before commits
- **Validation**: Check against schema before changes
- **Git Workflow**: Use conventional commits, test builds in CI

## Key Files & Patterns

### Configuration Structure
- **`flake.nix`**: Input definitions, follows pattern
- **`values.nix`**: User settings (create from schema)
- **`modules/shared/lib/values/default.nix`**: Type schemas
- **`modules/{darwin,nixos}/default.nix`**: System configs
- **`modules/home/default.nix`**: User configs

### Module Patterns
```nix
# default.nix
{ config, lib, ... }: {
  imports = [ ./name.nix ];
}

# name.nix
{ config, lib, values, ... }: {
  # Implementation
}
```

### Lua Plugin Pattern
```lua
local M = {}

M.plugins = {
  {
    "plugin/name",
    opts = function()
      return {
        -- Configuration
      }
    end,
  }
}

return M
```

## Testing & Validation

### Pre-Commit Checks
1. `task fmt:all:check` - Formatting validation
2. `task nix:build` - Build validation
3. `task nix:validate` - Flake validation
4. Manual review of changes

### Build Testing
- Test specific systems: `task nix:build:lv426` or `task nix:build:arrakis`
- Full validation: `task nix:build:all`
- Apply changes: `task nix:refresh` (use cautiously)

## Common Workflows

### Adding a New Package
1. Add to `values.nix`: `nix.additionalPackages = [ "pkg-name" ];`
2. Test: `task nix:build`
3. Apply: `task nix:refresh`

### Modifying Neovim Config
1. Edit `modules/home/configurations/neovim/lua/sysinit/`
2. Format: `task fmt:lua`
3. Test: `task nix:build`
4. Apply: `task nix:refresh`

### Adding System Service
1. Create module in appropriate `modules/{darwin,nixos}/`
2. Import in `default.nix`
3. Define options in values schema if configurable
4. Test build and apply

---

This file provides coding guidelines for agentic assistants. See README.md for user documentation.</content>
<parameter name="filePath">AGENTS.md
