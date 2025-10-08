# sysinit Constitution

## Core Principles

### I. Modular Configuration Architecture

All system configurations MUST follow the modular structure:
- Each configuration module lives in `modules/{platform}/configurations/{tool}/`
- Modules MUST have a `default.nix` that imports configuration files
- Modules MUST be self-contained with their own configs, themes, and dependencies
- Each module exports configuration via Nix home-manager or darwin-nix APIs
- Configuration files (YAML, TOML, Lua, etc.) belong alongside their module, not scattered

### II. Declarative Values Schema

All user-configurable values MUST be:
- Defined in `modules/lib/values/default.nix` with proper type annotations
- Validated in `modules/lib/validation/default.nix` with clear error messages
- Documented automatically via `hack/generate-values-docs.sh` → README.md
- Set by users in root-level `values.nix` file only
- Never hardcoded - use the `values` parameter passed to modules

### III. Theme System Consistency

All applications with visual configuration MUST:
- Use the centralized theme system in `modules/lib/theme/`
- Support theme variants (catppuccin, kanagawa, rose-pine, gruvbox, solarized, nord)
- Deploy theme files via `utils.themes.deployThemeFiles` or similar helpers
- Store theme files in `{module}/themes/{colorscheme}-{variant}.{ext}` format
- Respect transparency settings from `values.theme.transparency`

### IV. Task Automation via go-task

Build, format, and deployment automation MUST use:
- Root `Taskfile.yml` for project-wide tasks with clear descriptions
- Subtasks in `tasks/` directory (e.g., `nix.yml`, `format.yml`)
- Consistent logging via `LOGGING_FUNCTIONS` (log_info, log_warn, log_error, log_success)
- Error handling with proper exit codes (`ERROR_EXIT_CODE=1`, `SUCCESS_EXIT_CODE=0`)
- Silent mode by default, with structured output only

### V. Nix-First Dependency Management

Package management MUST follow this hierarchy:
1. **Nix packages**: Primary source via `nixpkgs` (in `modules/{platform}/packages/`)
2. **Language-specific managers**: For languages that need latest versions
   - Go: via `go.additionalPackages` (go install)
   - Rust: via `cargo.additionalPackages` (cargo install)
   - Python: via `pipx.additionalPackages` or `uvx.additionalPackages`
   - Node: via `npm.additionalPackages` or `yarn.additionalPackages`
   - Homebrew (macOS only): via `darwin.homebrew.additionalPackages` for GUI apps
3. All additional packages configured via `values.nix` schema, never hardcoded

### VI. Utility Library Pattern

Reusable functionality MUST be extracted to `modules/lib/`:
- `paths/`: Path manipulation helpers
- `platform/`: Platform detection (Darwin vs Linux)
- `shell/`: Shell script utilities (e.g., `stripHeaders`)
- `theme/`: Theme system (palettes, adapters, presets)
- `validation/`: Input validation functions
- `values/`: Values schema definitions
- Export via `modules/lib/default.nix` for use as `utils.{category}.{function}`

### VII. Documentation as Code

Documentation MUST be:
- Generated from source where possible (see `hack/generate-values-docs.sh`)
- Injected into README.md between marker comments (`<!-- MARKER_START -->` / `<!-- MARKER_END -->`)
- ASCII art and visual elements encouraged for engagement
- Environment variables documented in a standardized table format
- Up-to-date with schema changes via automation (`task docs:values`)

## Platform-Specific Constraints

### macOS (Darwin)

- Use `nix-darwin` for system-level configuration (Dock, Finder, keyboard, etc.)
- System configurations live in `modules/darwin/configurations/`
- GUI applications via Homebrew Casks when not available in nixpkgs
- Services (borders, sketchybar, aerospace) configured as launch agents
- Integration with macOS-specific tools (Hammerspoon, AeroSpace, etc.)

### Home Manager

- User-level configurations live in `modules/home/configurations/`
- All dotfiles managed declaratively via `home.file` or `xdg.configFile`
- Shell configurations (zsh, nu) with modular imports for ui/system/tools
- Editor configurations (neovim, helix, vscode) with full plugin management
- XDG Base Directory compliance required

## Development Workflow

### Feature Development (.specify workflow)

When adding features using the `.specify` workflow:

1. **Feature Specification**: Follow `spec-template.md` structure
   - User stories MUST be prioritized (P1, P2, P3) and independently testable
   - Requirements MUST use FR-### format with clear "MUST" statements
   - Success criteria MUST be measurable and technology-agnostic
   
2. **Implementation Planning**: Follow `plan-template.md` structure
   - Technical context MUST document all technology choices
   - Constitution Check MUST verify compliance before Phase 0
   - Project structure MUST match repository conventions
   - Complexity violations MUST be justified with alternatives considered
   
3. **Branch Naming**: Use `###-feature-name` format (e.g., `001-agent-cli-hooks`)
   - Corresponding spec directory at `specs/###-feature-name/`
   - All planning artifacts (spec.md, plan.md, research.md, etc.) live there

### Code Quality

- **Formatting**: Use `task fmt` to format all supported file types
- **Nix code**: Must pass `nix flake check` and format with nixfmt (width=100)
- **Shell scripts**: Must pass shellcheck, formatted with shfmt (options: `-i 2 -ci -sr -kp -fn`)
- **Validation**: All user-facing values must have validation in `modules/lib/validation/`
- **Error messages**: Must be actionable with clear next steps

### Git Configuration

- Default branch: `main`
- Hooks directory: `.githooks/` (set in gitconfig)
- Commits: Use conventional format, amend freely before push
- Auto-setup remote on push enabled
- Rebase on pull by default
- Merge strategy: zdiff3 conflict style

## Governance

This constitution defines the architectural patterns and constraints for sysinit. All changes to configurations, modules, and tooling MUST:

1. Follow the modular architecture patterns defined above
2. Validate user inputs with clear error messages
3. Integrate with the theme system when visual configuration is involved
4. Be documented in code where possible (schemas, types, validation)
5. Use the task automation system for any repeated operations

**Complexity Justification**: Any deviation from these patterns requires documented justification explaining:
- What simpler alternative was considered
- Why the simpler alternative is insufficient
- What specific problem the complexity solves

**Constitution Amendments**: Changes to these principles require:
- Update to this file with rationale
- Update to affected templates and scripts
- Migration guide for existing configurations

**Version**: 1.0.0 | **Ratified**: 2025-10-08 | **Last Amended**: 2025-10-08
