<!--
SYNC IMPACT REPORT
==================
Version Change: 1.0.0 → 1.0.1
Date: 2025-11-04

Modified Principles:
- None (restoration of concrete content from template)

Added Sections:
- None

Removed Sections:
- None

Change Summary:
- PATCH version bump: Restored sysinit-specific constitution content that was
  accidentally replaced with template placeholders. This is a non-semantic fix
  that returns the constitution to its proper state without changing governance
  rules or principles.

Templates Requiring Updates:
✅ plan-template.md - Reviewed, constitution check section aligns
✅ tasks-template.md - Reviewed, task structure aligns with principles
✅ spec-template.md - Reviewed, requirements format aligns
✅ agent-file-template.md - Reviewed, no agent-specific references to update

Follow-up TODOs:
- None
-->

# sysinit Constitution

## Core Principles

### I. Nix-First Architecture
All system configurations, package management, and dotfiles are declared in Nix. This ensures:
- **Declarative configuration**: System state is explicitly defined, not implied
- **Reproducibility**: Same configuration produces identical results across machines
- **Atomic updates**: Changes are applied atomically with rollback capability
- **Single source of truth**: `values.nix` is the central configuration point

**NON-NEGOTIABLE**: New features MUST be implemented as Nix modules in the appropriate directory structure (`modules/darwin/`, `modules/home/`, or `modules/lib/`).

### II. Modular Organization
Each tool/application gets its own module with clear boundaries:
- **Self-contained modules**: Each configuration lives in `modules/[domain]/configurations/[tool]/`
- **Separation of concerns**: Darwin (system-level) vs Home Manager (user-level) configurations are distinct
- **Reusable utilities**: Shared logic lives in `modules/lib/` (theme, validation, packages, etc.)
- **Clear imports**: Each module explicitly declares its dependencies

### III. Values-Driven Configuration
User-specific settings are centralized in `values.nix` with strict validation:
- **Schema-first**: All configuration options are defined in `modules/lib/values/default.nix`
- **Type safety**: Use Nix type system (`types.str`, `types.bool`, `types.listOf`, etc.)
- **Validation rules**: Critical values (hostname, email, etc.) have validators in `modules/lib/validation/`
- **Defaults with overrides**: Sensible defaults are provided, user can override per-machine
- **Documentation**: Values schema auto-generates README documentation via `hack/generate-values-docs.sh`

### IV. Theme System
Consistent theming across all applications through abstraction:
- **Palette definitions**: Color schemes defined in `modules/lib/theme/palettes/`
- **Semantic mapping**: Colors mapped to semantic roles (background, foreground, accent, etc.)
- **Application adapters**: Each app (wezterm, neovim, firefox) has an adapter in `modules/lib/theme/adapters/`
- **Runtime generation**: Theme configs are generated at build time from palette + adapter + user preferences
- **Multi-theme support**: Supports Catppuccin, Kanagawa, Rose Pine, Gruvbox, Solarized, Nord

### V. Symlink-Based Live Development
For rapid iteration, certain configurations use out-of-store symlinks:
- **Neovim configs**: Point directly to repo for instant updates without rebuild
- **Development efficiency**: Changes to Lua/shell configs take effect immediately
- **Build-time artifacts**: Generated configs (theme JSONs) still go through Nix
- **Selective use**: Only apply to frequently-iterated configs (editor, shell integrations)

## Architectural Constraints

### Directory Structure
```
modules/
├── darwin/           # System-level (macOS) configurations
│   ├── configurations/
│   └── packages/
├── home/             # User-level configurations (home-manager)
│   ├── configurations/
│   └── packages/
└── lib/              # Shared utilities and libraries
    ├── packages/     # Package management utilities
    ├── paths/        # Path helpers
    ├── platform/     # Platform detection
    ├── shell/        # Shell script utilities
    ├── theme/        # Theme system
    ├── validation/   # Configuration validators
    └── values/       # Values schema definitions
```

### Package Management
Multiple package managers coexist, managed through Nix activation scripts:
- **Nix packages**: Declared in `modules/home/packages/nixpkgs/`
- **Homebrew**: System packages via `nix-homebrew` in `modules/darwin/packages/homebrew.nix`
- **Language-specific**: Go, Cargo, npm, pipx, uvx, etc. via activation hooks
- **Extensibility**: Each manager has `additionalPackages` list in values.nix
- **Idempotency**: Package install scripts check before installing

### Configuration Validation
All user configurations are validated at eval time:
- **Hostname validation**: Must be valid DNS hostname format
- **Email validation**: Basic email format checking
- **Theme validation**: Colorscheme and variant must exist
- **Package lists**: Non-empty strings only
- **Early failure**: Invalid configs fail at `nix build` time, not runtime

## Development Workflow

### Adding New Tool Configuration
1. Determine if it's system-level (Darwin) or user-level (Home Manager)
2. Create `modules/[domain]/configurations/[tool]/` directory
3. Create `default.nix` (imports sub-configs) and `[tool].nix` (main config)
4. If theming: add theme files in `themes/` subdirectory
5. If packages: add to appropriate package manager in `modules/home/packages/`
6. Add values schema entries in `modules/lib/values/default.nix` if needed
7. Update `modules/[domain]/configurations/default.nix` to import new module
8. Run `task docs:values` to update README

### Testing Changes
- **Build without apply**: `task nix:build` validates configuration
- **Apply changes**: `task nix:refresh` rebuilds and switches generations
- **Format code**: `task fmt` formats all Nix files with nixfmt
- **Rollback**: `darwin-rebuild --rollback` reverts to previous generation

### Values Schema Updates
When adding new configuration options:
1. Add to `modules/lib/values/default.nix` with proper type and description
2. Add validation if needed in `modules/lib/validation/default.nix`
3. Run `task docs:values` to auto-generate documentation in README
4. Update `values.nix` with new values (or rely on defaults)

## Quality Standards

### Nix Code Style
- **Formatting**: Use nixfmt with 100-character line width
- **Imports**: Group by category (lib, config, pkgs, values, utils)
- **Let bindings**: Extract complex logic into named variables
- **Attribute sets**: Use recursive `rec` only when necessary
- **Functions**: Prefer attribute set arguments with explicit destructuring

### Documentation
- **README**: Maintains task list, environment variables, and values schema
- **Comments**: Use for non-obvious logic or constraints
- **Inline docs**: `description` field required for all mkOption definitions
- **Examples**: Provide in comments for complex configurations

### Git Practices
- **Hooks directory**: `.githooks/` contains setup scripts
- **Commit hooks**: Can enforce validation before commits
- **Branch naming**: Not enforced (personal repo, may have work fork)
- **Configuration snapshots**: Lock file (`flake.lock`) tracked for reproducibility

## Non-Goals & Boundaries

### What This System Does NOT Do
- **Multi-user support**: Optimized for single user per machine
- **Cross-platform**: macOS (darwin) only, not NixOS/Linux
- **Server deployments**: Desktop development environment, not server configs
- **Secrets management**: External OAuth tokens and credentials via environment variables
- **Testing frameworks**: No automated tests for Nix configurations (validated at build time)

### Complexity Justification Required For
Adding any of the following requires documented rationale:
- New top-level `modules/` subdirectory
- New theme palette (vs. using existing)
- New package manager integration
- Breaking changes to values schema
- Alternatives to symlink-based configs

## Feature Specification Process

### Using `.specify/` Directory
The `.specify/` directory contains templates and scripts for structured feature planning:
- **Templates**: Spec, plan, tasks, and checklist templates
- **Scripts**: Setup, context update, and prerequisite checking
- **Memory**: Constitution (this file) and project-specific context

### Feature Branch Workflow (Optional)
For major changes:
1. Run `.specify/scripts/bash/create-new-feature.sh` to generate feature branch and spec
2. Fill out `specs/[###-feature]/spec.md` with user stories and requirements
3. Run `/speckit.plan` (if agent integration configured) to generate implementation plan
4. Implement changes following the constitution
5. Validate with `task nix:build` before committing

**NOTE**: Feature branch naming (`001-feature-name`) is advisory, not enforced in personal repo.

## Governance

**Constitution Authority**: This constitution guides all development decisions for the sysinit repository. Changes to core principles require documentation and validation that the change improves the system's maintainability, reproducibility, or usability.

**Validation Enforcement**: All configuration changes MUST pass Nix evaluation and validation checks. Invalid configurations that fail `task nix:build` MUST NOT be merged.

**Documentation Currency**: The README.md values schema section is auto-generated and MUST be kept in sync with `modules/lib/values/default.nix` by running `task docs:values` before committing values schema changes.

**Simplicity First**: When choosing between multiple valid approaches, prefer the simpler, more explicit solution. Complex abstractions require clear justification in commit messages.

**Work Fork Compatibility**: Some users maintain work-specific forks. Breaking changes to the values schema or module structure should be considered carefully and documented in commit messages.

---

**Version**: 1.0.1 | **Ratified**: 2024-08-07 | **Last Amended**: 2025-11-04
