# AGENTS.md

Nix-flakes configuration for macOS (Apple Silicon) and NixOS. Reproducible system setup via nix-darwin + home-manager.

## Essential Commands

### Build/Test/Apply
```bash
task nix:build                # Test current system config (default: lv426/macOS)
task nix:build:lv426          # Build/test macOS config specifically
task nix:build:arrakis        # Build/test NixOS config specifically
task nix:build:all            # Build all system configurations
task nix:build:work           # Dry-run build for work config (reduced resources)
task nix:refresh              # Apply current config to system (use with caution)
task nix:refresh:lv426        # Apply macOS config
task nix:refresh:arrakis      # Apply NixOS config
```

### Format/Lint
```bash
task fmt                      # Format all (Nix, Lua, Shell)
task fmt:nix                  # Format Nix files only
task fmt:nix:check            # Check Nix formatting (no changes)
task fmt:lua                  # Format Lua files only
task fmt:lua:check            # Check Lua formatting (no changes)
task fmt:lua:lint             # Run LSP diagnostics on Lua
task fmt:lua:validate         # Full Lua validation (format + lint)
task fmt:sh                   # Format shell scripts
task fmt:sh:check             # Check shell formatting (no changes)
task fmt:all:check            # Check all formatting without changes
```

### Validation/Testing
```bash
task nix:validate             # Validate flake configuration
nix flake check               # Direct flake validation
nix eval .#checks.x86_64-linux.<system> --json  # Evaluate specific check
```

### Maintenance
```bash
task nix:update               # Update flake inputs and commit
task nix:clean                # Cleanup old generations
task nix:config               # Copy nix configs to /etc/nix/
task nix:config:user          # Setup user-level nix.conf
task nix:secrets:init         # Initialize secrets with GitHub token
task docs:values              # Generate values.nix documentation
```

## Code Style Guidelines

### Nix
- **Formatting**: `nixfmt --width=100`
- **Structure**: `default.nix` for entry points, `name.nix` for implementations
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
- **Logging**: Source `{{.LOGLIB_PATH}}`, use `log_*` functions
- **Formatting**: `shfmt -i 2 -ci -sr -s -w`
- **Executability**: All `.sh` files must be executable
- **Error Handling**: Check command success, meaningful errors
- **Variables**: Use `local` in functions, quote all variables

### General Rules
- **No Emojis**: Strictly enforced
- **DRY**: Extract repeated patterns to shared utilities
- **Comments**: Use for complex logic only
- **Testing**: Run `task nix:build` before commits

## Key Files & Patterns

### Configuration Structure
- **`flake.nix`**: Input definitions and output routing
- **`values.nix`**: User settings (create from schema in `modules/shared/lib/values/default.nix`)
- **`modules/shared/lib/values/default.nix`**: Type schemas and validation
- **`modules/darwin/default.nix`**: macOS system configuration
- **`modules/nixos/default.nix`**: NixOS system configuration
- **`modules/home/default.nix`**: User-level home-manager configuration

### Module Patterns
```nix
# default.nix (entry point)
{ config, lib, ... }: {
  imports = [ ./name.nix ];
}

# name.nix (implementation)
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
1. `task fmt:all:check` - Verify formatting (no modifications)
2. `task nix:validate` - Validate flake syntax
3. `task nix:build` - Build-time validation
4. Manual review of changes

### Single System Testing
- Test macOS only: `task nix:build:lv426`
- Test NixOS only: `task nix:build:arrakis`
- Dry-run work build: `task nix:build:work --dry-run`

---

This file provides coding guidelines for agentic assistants. See README.md for user documentation.

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
