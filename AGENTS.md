# AGENTS.md

Comprehensive configuration and guidance for AI coding agents working with this Nix-based macOS development environment.

## Project Overview

This is a Nix-flakes based macOS development environment using:
- **nix-darwin** for system-level configuration  
- **home-manager** for user environment management
- **Nix flakes** for reproducible configuration
- Target platform: macOS (Apple Silicon / `aarch64-darwin`)

## Essential Commands

### Building and Applying Changes
```bash
# Apply full system configuration (recommended workflow)
task nix:refresh

# Build without applying (check for errors)
task nix:build

# Update flake inputs and apply
task nix:update

# Clean up old generations
task nix:clean
```

### Development Workflow
```bash
# Format all code (Nix, Lua, Shell)
task fmt

# Test configuration changes
task nix:build && task nix:refresh

# Work configuration (reduced resource footprint)
task nix:refresh:work
```

## Architecture

### Module System
- `modules/shared/lib/` - Shared utilities and theme system (cross-platform)
- `modules/darwin/` - macOS system-level configurations (nix-darwin)
  - `system/` - System-level config (requires sudo)
  - `home/` - macOS home-manager configurations
- `modules/home/` - Cross-platform user-level configurations (home-manager)

### Values-Based Configuration
All user settings centralized in `values.nix`:
- Type-checked against schema in `modules/shared/lib/values/default.nix`
- Validated at build-time in `modules/shared/lib/nixos-modules/validation.nix`
- Auto-documented in README.md

### Theme System
Centralized in `modules/shared/lib/theme/` with three layers:
1. **Palette Layer** - Color definitions (rose-pine, catppuccin, gruvbox, etc.)
2. **Semantic Layer** - Color role mapping  
3. **Adapter Layer** - App-specific transformation

### Out-of-Store Symlinks
Critical for development - configuration files use `mkOutOfStoreSymlink` for live editing without rebuilds.

## LLM Configuration System

### Structure
```
modules/home/configurations/llm/
├── config/           # LLM client configurations
│   ├── claude.nix    # Claude Desktop MCP configuration
│   ├── goose.nix     # Goose AI assistant configuration  
│   ├── opencode.nix  # Opencode IDE configuration
│   └── cursor-agent.nix # Cursor CLI permissions
├── prompts/          # Specialized agent prompts
│   ├── ai-engineer.nix
│   ├── agent-organizer.nix
│   ├── backend-architect.nix
│   ├── frontend-developer.nix
│   ├── typescript-expert.nix
│   ├── platform-engineer.nix
│   ├── api-documenter.nix
│   └── context-manager.nix
├── shared/           # Common configurations
│   ├── prompts.nix    # Prompt management
│   ├── lsp.nix       # Language server configuration
│   ├── mcp-servers.nix # MCP server definitions
│   └── common.nix    # Utility functions
└── default.nix       # Main entry point
```

### MCP Servers
Comprehensive MCP server setup including:
- **AWS Services**: EKS, CloudTrail, Terraform, API
- **Development Tools**: Git, fetch, ast-grep, context7
- **Project Integration**: Serena (project-aware coding assistant)

### Agent Prompts
Specialized prompts for different roles with:
- Structured instruction format
- Tool integration guidance
- Best practices and requirements
- Activity-specific focus areas

## Development Guidelines

### Editing Configurations
1. **Neovim, Wezterm, Zsh**: Edit directly - changes apply immediately via out-of-store symlinks
2. **System Configuration**: Edit `values.nix` then run `task nix:refresh`
3. **LLM Prompts**: Edit prompt files in `modules/home/configurations/llm/prompts/`

### Adding Packages
Edit `values.nix`:
```nix
{
  nix.additionalPackages = [ "new-package" ];
  cargo.additionalPackages = [ "cargo-new" ];
  npm.additionalPackages = [ "typescript" ];
}
```

### Changing Theme
Edit `values.nix`:
```nix
{
  theme = {
    colorscheme = "catppuccin";  # rose-pine, gruvbox, nord, kanagawa, etc.
    variant = "mocha";            # theme-specific variant
    appearance = "dark";          # light or dark
    transparency = {
      enable = true;
      opacity = 0.65;
      blur = 40;
    };
  };
}
```

## Testing and Validation

### Pre-commit Checks
Always test before applying:
```bash
# Build to check for errors
task nix:build

# If successful, apply
task nix:refresh
```

### Validation Levels
1. **Type checking** - Values schema enforces types
2. **Build-time validation** - Assertions check compatibility  
3. **Theme validation** - Ensures variant availability
4. **Nix evaluation** - Catches syntax errors

## Security Considerations

### MCP Server Security
- AWS servers use regional isolation (us-east-1)
- Sensitive data access flags are explicitly enabled
- Environment variables properly scoped
- Error logging levels configured

### Execution Environment
- Nix provides sandboxed package management
- Out-of-store symlinks prevent rebuild surprises
- Configuration validation at multiple levels
- Git hooks ensure code quality

## Multi-Ecosystem Package Management

Packages installed from multiple ecosystems:
- **Nix** - Primary package manager (CLI tools)
- **Homebrew** - macOS-specific packages and GUI apps
- **Cargo** - Rust development tools
- **Go** - Go binaries
- **npm/yarn** - Node.js global packages
- **pipx/uvx** - Python isolated applications
- **gh extensions** - GitHub CLI plugins
- **krew** - kubectl plugins

## Agent-Specific Instructions

### For Code Generation
1. Use existing module patterns and conventions
2. Follow the established file structure
3. Include proper type definitions in values schema
4. Add validation where appropriate
5. Update documentation strings

### For Configuration Changes
1. Check if change affects system or user level
2. Determine if rebuild is required
3. Use appropriate configuration pattern
4. Test with `task nix:build` before applying
5. Update relevant documentation

### For Dependency Management
1. Check if dependency exists in nixpkgs first
2. Use overlays for version overrides if needed
3. Consider multi-ecosystem approach
4. Add to appropriate `additionalPackages` field
5. Test with clean environment

## Common Workflows

### Adding New LLM Configuration
1. Create config file in `modules/home/configurations/llm/config/`
2. Import in `modules/home/configurations/llm/default.nix`
3. Add values schema options in `modules/lib/values/default.nix`
4. Add to `values.nix` if user-configurable
5. Test with `task nix:build`

### Adding New Agent Prompt
1. Create prompt file in `modules/home/configurations/llm/prompts/`
2. Follow established prompt structure with instruction/requirements/best_practices
3. Add to prompt list in `modules/home/configurations/llm/shared/prompts.nix`
4. Test with LLM client of choice

### Debugging Configuration Issues
1. Check `task nix:build` output for specific errors
2. Validate values.nix against schema
3. Check for missing imports or circular dependencies
4. Verify theme/variant compatibility
5. Review Nix evaluation logs

## File Organization Conventions

### Module Structure Pattern
```
config-name/
├── default.nix          # Entry point that imports implementation
└── [name].nix          # Implementation with actual config
```

### Naming Conventions
- **Configurations**: `modules/{darwin,home}/configurations/`
- **Packages**: `modules/{darwin,home}/packages/`
- **Libraries**: `modules/lib/`
- **Overlays**: `overlays/packages.nix`

## Special Files

- **`flake.nix`** - Main flake entry point
- **`values.nix`** - User configuration (most edited file)
- **`Taskfile.yml`** - Task runner configuration
- **`AGENTS.md`** - This file - agent-specific guidance

## Performance Optimization

### Build Performance
- Use `task nix:build:work` for reduced resource footprint
- Clean old generations with `task nix:clean`
- Use binary cache where possible

### Runtime Performance  
- Out-of-store symlinks for live editing
- Lazy loading in application configurations
- Optimized theme generation

## Troubleshooting

### Common Issues
1. **Build failures**: Check values.nix syntax and schema compliance
2. **Theme issues**: Verify variant availability for colorscheme
3. **MCP server failures**: Check AWS credentials and network connectivity
4. **Permission errors**: Ensure proper file permissions for symlinks

### Getting Help
- Check Nix evaluation logs for detailed error messages
- Review validation output for specific issues
- Consult schema definitions for required fields
- Test changes incrementally

## Build/Lint/Test Commands

```bash
# Build and apply configuration
task nix:refresh          # Apply full system configuration
task nix:build           # Build without applying (check errors)
task nix:update          # Update flake inputs and apply
task nix:clean           # Clean old generations

# Format all code
task fmt                 # Format Nix, Lua, Shell files
task format:all:check    # Check formatting without modifying

# Validation
task nix:validate        # Run flake check (format validation)
task format:lua:validate # Lua format check + LSP diagnostics
```

## Code Style Guidelines

### Nix Files
- Use `nixfmt --width=100` for formatting
- Follow module structure: `default.nix` (entry) + `[name].nix` (implementation)
- Import paths: `modules/{darwin,home}/configurations/` for configs, `modules/lib/` for utilities
- Type definitions in `modules/lib/values/default.nix` schema

### Lua Files  
- Use `stylua` for formatting
- Run `lua-language-server` diagnostics via `task format:lua:lint`
- Located in: `modules/home/configurations/{neovim,wezterm,hammerspoon,sketchybar}/`

### Shell Files
- Use `shfmt -i 2 -ci -sr -s -w` for formatting
- Make all `.sh` files executable: `task sh:chmod`
- Use `set -euo pipefail` and source `{{.LOGLIB_PATH}}` for logging

### General Conventions
- No emojis in code
- Use `mkOutOfStoreSymlink` for live-editable config files
- Test changes with `task nix:build` before applying
- Follow existing patterns and module structure

This AGENTS.md file serves as the primary guide for AI agents working with this configuration system. It complements the human-focused README.md by providing the detailed technical context needed for effective automated development assistance.