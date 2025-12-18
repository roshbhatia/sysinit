# AGENTS.md

Nix-flakes configuration for macOS (Apple Silicon) and NixOS. Reproducible system setup via nix-darwin + home-manager.

## Quick Reference

### Essential Commands
```bash
task nix:build       # Test configuration
task nix:refresh     # Apply configuration
task fmt            # Format Nix/Lua/Shell
task nix:clean      # Cleanup old generations
task nix:update     # Update dependencies
```

### Key Files
- **`values.nix`** - All user settings (centralized, type-checked)
- **`flake.nix`** - Main entry point
- **`modules/shared/lib/values/default.nix`** - Schema/types
- **`Taskfile.yml`** - Task runner config

## Architecture

### Directory Structure
```
modules/
├── shared/lib/           # Shared utilities, theme system
├── darwin/
│   ├── system/          # System-level config (nix-darwin)
│   └── home/            # macOS home-manager
└── home/                # Cross-platform user config
```

### Core Concepts
- **Values-driven**: All config in `values.nix`, type-checked against schema
- **Out-of-store symlinks**: Live editing for neovim/wezterm/zsh (no rebuild)
- **Module pattern**: `default.nix` (entry) + `name.nix` (impl)
- **Multi-ecosystem**: Nix, Homebrew, Cargo, npm, Go, pipx, etc.

### Theme System
Three-layer system in `modules/shared/lib/theme/`:
1. **Palette** - Color definitions
2. **Semantic** - Role mapping (background, foreground, etc.)
3. **Adapter** - App-specific transforms

## Code Style

### Nix
- Format: `nixfmt --width=100` (via `task fmt:nix`)
- Structure: `default.nix` imports `name.nix`
- Types: Define in `modules/shared/lib/values/default.nix`
- Settings: Put user-configurable options in `values.nix`

### Lua
- Format: `stylua` (column_width=100, indent_width=2)
- Lint: `task fmt:lua:lint` before commit
- Location: `modules/home/configurations/{neovim,wezterm,hammerspoon,sketchybar}/lua/`

### Shell
- Format: `shfmt -i 2 -ci -sr -s -w`
- Required: `set -euo pipefail` at start
- Required: Source `{{.LOGLIB_PATH}}` for logging functions
- Required: All `.sh` files executable (`task sh:chmod`)
- Log functions: `log_info`, `log_success`, `log_error`, `log_warn`

### General
- No emojis in code (enforced)
- Use `mkOutOfStoreSymlink` for live-editable configs
- Always test: `task nix:build` before changes
- Validate: Check against schema before commit

## Configuration Workflows

### Editing Config Files
- **Live-edit** (neovim, wezterm, zsh): Edit directly → changes immediate
- **System config**: Edit `values.nix` → `task nix:refresh`
- **LLM prompts**: Edit `modules/home/configurations/llm/prompts/`

### Adding Packages
Edit `values.nix`:
```nix
{
  nix.additionalPackages = [ "pkg-name" ];
  cargo.additionalPackages = [ "cargo-pkg" ];
  npm.additionalPackages = [ "npm-pkg" ];
  # Also: go, pipx, uvx, krew, yarn, gh
}
```

### Changing Theme
Edit `values.nix`:
```nix
{
  theme = {
    colorscheme = "catppuccin";      # ID from themes table in README
    variant = "macchiato";             # variant name
    appearance = "dark";               # or "light"
    transparency = {
      enable = true;
      opacity = 0.65;
      blur = 40;
    };
  };
}
```

## LLM Configuration

### Structure
```
modules/home/configurations/llm/
├── config/           # Client configs (claude, goose, opencode, cursor-agent)
├── prompts/          # Agent prompts
├── shared/           # Common (prompts.nix, lsp.nix, mcp-servers.nix)
└── default.nix
```

### MCP Servers
Configured in `modules/home/configurations/llm/shared/mcp-servers.nix`:
- AWS: EKS, CloudTrail, Terraform, API
- Dev Tools: Git, fetch, ast-grep, context7
- Project: Serena (coding assistant)

### Agent Prompts
Located in `modules/home/configurations/llm/prompts/`:
- Structure: instructions, requirements, best_practices sections
- Integrated with LLM tools and code symbols
- Test with LLM client of choice

## Testing & Validation

### Validation Levels
1. Type checking (values schema)
2. Build-time assertions
3. Theme variant compatibility
4. Nix evaluation errors

### Before Committing
```bash
task nix:build          # Check for errors
task fmt:all:check      # Check formatting
task format:lua:lint    # Lua diagnostics
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Build failure | Check `values.nix` syntax and schema compliance |
| Theme issues | Verify variant exists for colorscheme |
| MCP server fails | Check AWS credentials and network |
| Permission errors | Verify symlink file permissions |

## Debugging Configuration Issues
1. Check `task nix:build` output for errors
2. Validate `values.nix` against schema
3. Check for missing imports or circular deps
4. Verify theme/variant compatibility
5. Review Nix evaluation logs

## Common Tasks

### Add LLM Configuration
1. Create config in `modules/home/configurations/llm/config/`
2. Import in `modules/home/configurations/llm/default.nix`
3. Add schema options if needed
4. Add to `values.nix` if user-configurable
5. Test: `task nix:build`

### Add Agent Prompt
1. Create file in `modules/home/configurations/llm/prompts/`
2. Follow structure: instructions/requirements/best_practices
3. Add to `modules/home/configurations/llm/shared/prompts.nix`
4. Test with LLM client

### Add Code to Module
1. Use existing patterns and conventions
2. Add type definitions to schema
3. Include validation
4. Update docs
5. Test: `task nix:build`

### Manage Dependencies
1. Check nixpkgs first
2. Use overlays for version overrides if needed
3. Prefer multi-ecosystem approach
4. Add to appropriate `additionalPackages` field
5. Test in clean environment

## All Commands
```bash
# Build & apply
task nix:refresh              # Apply current (lv426/macOS)
task nix:refresh:lv426        # Apply macOS
task nix:refresh:arrakis      # Apply NixOS
task nix:refresh:work         # Apply work config
task nix:build                # Test build
task nix:build:work           # Test work config
task nix:update               # Update flake & apply
task nix:clean                # Cleanup store & generations

# Format
task fmt                      # Format all
task fmt:nix                  # Format Nix only
task fmt:lua                  # Format Lua only
task fmt:sh                   # Format Shell only
task fmt:all:check            # Check without modifying

# Validate
task nix:validate             # Check flake validity
task format:lua:lint          # Run Lua LSP diagnostics

# Setup
task nix:config               # Copy nix configs to /etc/nix
task nix:secrets:init         # Setup GitHub token
task sh:chmod                 # Make .sh files executable
```

## Multi-System Setup

Structure supports:
- **lv426** (macOS, Apple Silicon) 
- **arrakis** (NixOS) 

Each has system and home-manager configs in appropriate modules.

---

This file is a reference for LLM agents. See README.md for user-facing documentation and project overview.
