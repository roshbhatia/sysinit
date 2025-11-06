# Implementation Plan: Theme Configuration Audit & OpenCode Integration

**Branch**: `003-theme-audit` | **Date**: 2025-11-06 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-theme-audit/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Audit and fix theme configuration system to ensure all six palettes (Catppuccin, Rose Pine, Gruvbox, Solarized, Kanagawa, Nord) correctly propagate to all configured applications. Primary objective: integrate OpenCode into the unified theme system so it respects system appearance mode and palette settings through the existing theme infrastructure in `modules/lib/theme`.

**Technical Approach**:
1. Add OpenCode application adapters to all palette definitions
2. Update OpenCode configuration to use theme library's `getAppTheme` function instead of hardcoded "system"
3. Implement fallback strategy for Rose Pine and Solarized (which lack native OpenCode themes)
4. Audit all existing application adapters to ensure complete palette-variant coverage
5. Add comprehensive validation tests for theme configuration

## Technical Context

**Language/Version**: Nix (nixpkgs unstable channel)
**Primary Dependencies**: nix-darwin, home-manager, nixpkgs theme system (modules/lib/theme)
**Storage**: N/A (declarative configuration files)
**Testing**: Nix build-time evaluation + manual verification across applications
**Target Platform**: macOS (darwin) with nix-darwin
**Project Type**: Configuration management (Nix modules)
**Performance Goals**: Theme configuration changes complete within 30 seconds (Nix rebuild time)
**Constraints**:
- Must maintain backward compatibility with existing values.nix structure
- Validation must occur at Nix evaluation time (before builds)
- Cannot require external services or network access
- Must work within Home Manager's file deployment model
**Scale/Scope**:
- 6 theme palettes (Catppuccin, Rose Pine, Gruvbox, Solarized, Kanagawa, Nord)
- 12 applications (Wezterm, Neovim, Firefox, OpenCode, bat, delta, atuin, helix, vivid, k9s, sketchybar, nushell)
- ~72 palette-app combinations to validate

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Nix-First Architecture ✅
- **Compliant**: All changes are Nix module updates in `modules/lib/theme/palettes/` and `modules/home/configurations/llm/config/`
- **No violations**: Using existing module structure, not introducing non-Nix configuration

### II. Modular Organization ✅
- **Compliant**: Changes are isolated to theme system (`modules/lib/theme/`) and OpenCode config (`modules/home/configurations/llm/config/opencode.nix`)
- **Clear boundaries**: Palette adapters remain in palette files, OpenCode config consumes theme library functions
- **No violations**: Following existing patterns for application-specific theme integration

### III. Values-Driven Configuration ✅
- **Compliant**: Using existing `values.theme` structure (colorscheme, appearance, variant)
- **No schema changes**: All necessary configuration options already exist in values schema
- **No violations**: No new values.nix fields required

### IV. Theme System ✅
- **Compliant**: Extending existing theme system by adding OpenCode adapters to palettes
- **Following patterns**: Using same `appAdapters` structure as other applications (wezterm, neovim, bat, etc.)
- **No violations**: Pure extension of existing abstraction, not replacing or reimplementing

### V. Symlink-Based Live Development ✅
- **Compliant**: OpenCode config generated at build time through Home Manager
- **No violations**: Not introducing new symlink patterns, using standard Nix deployment

### Quality Standards ✅
- **Validation**: All changes validated at build time through Nix evaluation
- **Documentation**: Will update palette documentation to reflect OpenCode support
- **No violations**: Following existing code style and patterns

### Complexity Justification
**No complexity additions requiring justification**. This feature uses existing infrastructure and patterns without introducing new abstraction layers, package managers, or architectural components.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
modules/
├── lib/
│   └── theme/
│       ├── default.nix              # Core theme library (existing)
│       ├── palettes/
│       │   ├── catppuccin.nix       # [MODIFY] Add opencode adapter
│       │   ├── rose-pine.nix        # [MODIFY] Add opencode adapter
│       │   ├── gruvbox.nix          # [MODIFY] Add opencode adapter
│       │   ├── solarized.nix        # [MODIFY] Add opencode adapter
│       │   ├── kanagawa.nix         # [MODIFY] Add opencode adapter
│       │   └── nord.nix             # [MODIFY] Add opencode adapter
│       └── adapters/
│           └── opencode.nix         # [CREATE] OpenCode theme adapter (optional)
└── home/
    └── configurations/
        └── llm/
            └── config/
                └── opencode.nix      # [MODIFY] Use theme library instead of hardcoded "system"

specs/003-theme-audit/
├── validation-tests/                # [CREATE] Test scripts for validation
│   └── theme-audit.sh               # Iterates through all palette-app combinations
└── documentation/                   # [CREATE] Theme compatibility matrix
    └── theme-support.md             # Documents which palettes work with which apps
```

**Structure Decision**: Configuration-only changes to Nix modules. No new source code directories needed since this is pure configuration management. All theme logic already exists in `modules/lib/theme/default.nix`; we're extending palette definitions with OpenCode adapters and updating OpenCode config to consume the theme library.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No violations requiring justification** - all constitution checks passed.
