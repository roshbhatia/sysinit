# Module Structure Guide

This document outlines the organizational patterns and conventions used across the Nix configuration codebase.

## Directory Layout

```
modules/
├── darwin/              # macOS (nix-darwin) system configuration
├── nixos/              # NixOS system configuration
├── home/               # Cross-platform home-manager configuration
└── shared/lib/         # Shared utilities and libraries
```

## Architecture Patterns

### 1. System Modules (Darwin & NixOS)

```
darwin/
├── default.nix         # Main entry point (imports submodules)
├── home-manager.nix    # home-manager integration
├── packages/           # Package management (Nix, Homebrew, Cargo, etc.)
├── home/               # Platform-specific home-manager modules
│   ├── default.nix
│   └── configurations/ # macOS-only tools (hammerspoon, sketchybar)
└── configurations/     # System-level configuration modules
    ├── default.nix     # Import aggregator
    ├── aerospace/      # Individual configs (one per module)
    ├── dock/
    ├── keyboard/
    └── ...
```

**Key conventions**:
- Each module is a directory containing `default.nix` (idiomatic Nix pattern)
- Simple modules (< 50 lines) still use directory structure for consistency
- Platform-specific configs in `darwin/home/configurations` & `nixos/home/configurations` contain tools that don't exist on other platforms

### 2. Home-Manager Configuration

```
home/
├── default.nix         # Cross-platform base configuration
├── configurations/     # Shared across all platforms
│   ├── default.nix     # Import aggregator (34 modules)
│   ├── neovim/         # Complex modules with lib.nix
│   │   ├── default.nix
│   │   ├── impl.nix    # Implementation/helper functions
│   │   ├── init.lua    # Live-editable config
│   │   └── lua/        # Lua plugins and utilities
│   ├── wezterm/        # Similar structure
│   │   ├── default.nix
│   │   ├── impl.nix
│   │   ├── wezterm.lua
│   │   ├── lua/
│   │   └── colors/
│   ├── llm/            # Specialized complex module
│   │   ├── default.nix
│   │   ├── impl.nix
│   │   ├── config/     # LLM client configs (amp, claude, cursor, etc.)
│   │   ├── prompts/    # Agent prompts
│   │   └── shared/     # Common utilities
│   └── bat/            # Simple module (one default.nix only)
└── packages/           # Package management across package managers
```

**Key conventions**:
- Simple modules (< 50 lines, no subdirectories): Just `default.nix`
- Complex modules with Lua/helper code: `default.nix` + `impl.nix`
- Very complex modules with subsystems (llm): `default.nix` + `impl.nix` + subdirectories

### 3. Shared Utilities

```
shared/lib/
├── default.nix         # Main aggregator with grouped documentation
├── platform/           # System introspection (macOS, Linux, aarch64, etc.)
├── paths/              # Standard paths helper
├── xdg/                # XDG base directory paths
├── values/             # Configuration schemas and type definitions
├── theme/              # Theme system (palettes, semantic colors, adapters)
├── shell/              # Shell environment helpers and aliases
├── packages/           # Package manifest definitions
└── modules/            # NixOS-specific module utilities
```

**Key conventions**:
- Each subdirectory contains `default.nix` (entry) + supporting `.nix` files
- Grouped into logical categories in main `default.nix`:
  - **Core utilities**: platform, paths, xdg
  - **Configuration**: values, theme
  - **Runtime**: shell, packages, modules

## File Naming Conventions

### Module Entry Points
- **Required**: `default.nix` in each module directory
- **Purpose**: Imports aggregator or main configuration
- **Scope**: Module-level (namespace for imports)

### Implementation Files
- **Pattern**: `impl.nix` for helper functions and complex logic
- **Previous**: `lib.nix` (deprecated in favor of `impl.nix`)
- **Used in**: neovim, wezterm, atuin, firefox
- **Content**: Utility functions, transformations, adapters

### Configuration Files
- **Subdirectories**: Used for related assets (lua/, config/, prompts/)
- **Naming**: Descriptive names matching content type

### Assets
- **Live-editable configs**: `wezterm.lua`, `init.lua` (out-of-store symlinks)
- **Generated configs**: `theme_config.json`, `colors/` (generated from values)

## Pattern Examples

### Simple Module (1 file)
```nix
# bat/default.nix - Minimal configuration
{
  programs.bat.enable = true;
  programs.bat.config.theme = "Catppuccin Macchiato";
}
```

### Complex Module with Helpers
```nix
# neovim/default.nix
let
  themes = import ../../../shared/lib/theme { inherit lib; };
in {
  programs.neovim.enable = true;
  xdg.configFile."nvim/init.lua".source = ./init.lua;
  xdg.configFile."nvim/theme_config.json".text = builtins.toJSON (
    themes.generateAppJSON "neovim" values.theme
  );
}

# neovim/impl.nix - Helper functions (if needed)
{ lib }:
{
  someHelper = x: x + 1;
}
```

### Very Complex Module with Subsystems
```nix
# llm/default.nix - Entry point coordinating subsystems
{
  imports = [ ./config ./prompts ./shared ];
  
  programs.llm.enable = true;
}

# llm/config/amp.nix - Specific tool config
# llm/prompts/ai-engineer.nix - Agent prompt
# llm/shared/lsp.nix - Common utilities
```

## Home-Manager Integration

### Pattern
```
darwin/home-manager.nix     → imports ../home + ./home
nixos/home-manager.nix      → imports ../home + ./home + sharedModules
                            ↓
                          home/default.nix (cross-platform base)
                            ↓
                          home/configurations/ (34 shared modules)
                            ↓
            darwin/home/configurations/     nixos/home/configurations/
            (platform-specific overrides)   (platform-specific overrides)
```

### Consistency Rules
- Both `home-manager.nix` files accept: `values`, `utils`, `inputs ? { }`
- Both define `sharedModules = [...]` array (may be empty)
- Both import `../home` (shared) + `./home` (platform-specific)

## Shared Library Organization

The `shared/lib/default.nix` exports utilities grouped by concern:

```nix
# Core utilities for system and path management
platform   # System detection (Darwin/NixOS, aarch64/x86_64)
paths      # Standard location helpers
xdg        # XDG base directory spec

# Configuration helpers
values     # Type schemas and validation
theme      # Color system and app adapters

# Runtime utilities
shell      # Aliases, environment variables, completion
packages   # Package manifests across multiple managers

# NixOS utilities
modules    # Module system helpers
```

## Conventions Summary

| Aspect | Convention | Rationale |
|--------|-----------|-----------|
| Entry point | Always `default.nix` | Idiomatic Nix, clear module boundaries |
| Implementation | `impl.nix` not `lib.nix` | Avoid confusion with stdlib lib |
| Simple configs | Still use directories | Consistency, easier to add features later |
| Complex logic | Extract to `impl.nix` | Separation of concerns, easier testing |
| Assets | Keep in module subdirs | Keeps related files together |
| Shared lib | Grouped with comments | Self-documenting code organization |
| Parameters | Explicit (no unused) | Clear dependencies and contracts |

## Anti-Patterns to Avoid

❌ **Don't**: Use `lib.nix` for implementation files (ambiguous with stdlib lib)
✅ **Do**: Use `impl.nix` or module-specific names

❌ **Don't**: Create module files outside of directories (breaks import consistency)
✅ **Do**: Always use `modulename/default.nix` structure

❌ **Don't**: Leave unused parameters in module definitions
✅ **Do**: Only define parameters you actually use

❌ **Don't**: Mix platform-specific configs with shared ones
✅ **Do**: Use `darwin/home/configurations/` and `nixos/home/configurations/` for platform-specific modules

## Maintenance Notes

- When adding a new configuration, create `modules/home/configurations/<name>/default.nix`
- If it needs helpers, add `impl.nix` in the same directory
- If it has assets (Lua, colors, etc.), create subdirectories as needed
- Add the import to `modules/home/configurations/default.nix`
- For platform-specific configs, use `darwin/home/configurations/` or `nixos/home/configurations/`
- Update `shared/lib/default.nix` comments if adding new utility categories

## See Also

- **AGENTS.md**: Build and deployment commands
- **values.nix**: All user-configurable settings
- **flake.nix**: Main entry point and flake configuration
