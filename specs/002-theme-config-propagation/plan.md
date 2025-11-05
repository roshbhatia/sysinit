# Implementation Plan: Theme Configuration Propagation

**Branch**: `002-theme-config-propagation` | **Date**: 2025-11-04 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-theme-config-propagation/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Ensure robust theme configuration propagation for appearance mode (light/dark), color palette selection, and system font changes across all configured applications (Wezterm, Neovim, Firefox, shell integrations). Theme changes apply through Nix rebuild/activation with atomic updates, build-time validation, and clear error messages for invalid configurations. The system uses the existing modular theme system in `modules/lib/theme/` with palette definitions, semantic mapping, and application adapters.

## Technical Context

**Language/Version**: Nix (NixOS/nix-darwin configuration language)
**Primary Dependencies**: nix-darwin, home-manager, nixpkgs
**Storage**: Configuration files in Nix store, symlinks to dotfiles
**Testing**: Nix build validation, manual integration testing across applications
**Target Platform**: macOS (darwin) via nix-darwin
**Project Type**: System configuration (Nix modules)
**Performance Goals**: Build-time validation (<5s), instant config evaluation
**Constraints**: Must maintain atomic updates, rollback capability, declarative configuration
**Scale/Scope**: 4 core applications (Wezterm, Neovim, Firefox, shell), 6 palettes, light/dark modes, font selection

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Alignment with Core Principles

**I. Nix-First Architecture** ✅
- Feature will be implemented as Nix modules in `modules/lib/theme/` and related configuration modules
- All theme configuration is declarative in `values.nix`
- Changes apply atomically through Nix rebuild/activation
- Single source of truth maintained

**II. Modular Organization** ✅
- Theme system already modular: `modules/lib/theme/` contains palettes, adapters, presets
- Each application adapter is self-contained (wezterm.nix, neovim.nix, firefox.nix)
- Clear separation between theme library and application configurations
- No structural changes needed

**III. Values-Driven Configuration** ✅
- Theme configuration already centralized in `values.nix` via `theme.*` options
- Schema defined in `modules/lib/values/default.nix`
- Type safety already in place (types.str for colorscheme/variant)
- Will enhance validation for light/dark mode and font configuration

**IV. Theme System** ✅
- Feature directly enhances the existing theme system
- Will ensure palette definitions support both light and dark variants
- Application adapters will be validated for proper theme propagation
- Runtime generation already established

**V. Symlink-Based Live Development** ✅
- Theme JSON configs are generated at build time (not symlinked)
- No impact on symlink-based development workflow
- Changes to theme require rebuild (expected behavior)

### Gates Status

**All gates PASS** - No constitution violations. This feature enhances existing theme infrastructure without requiring new top-level modules, new package managers, or breaking schema changes.

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
│   ├── theme/                    # Theme system (existing - will enhance)
│   │   ├── core/
│   │   │   ├── types.nix        # Theme type definitions
│   │   │   ├── utils.nix        # Theme utilities
│   │   │   └── constants.nix    # Theme constants
│   │   ├── palettes/            # Palette definitions (will add light/dark variants)
│   │   │   ├── catppuccin.nix
│   │   │   ├── kanagawa.nix
│   │   │   ├── rose-pine.nix
│   │   │   ├── gruvbox.nix
│   │   │   ├── solarized.nix
│   │   │   └── nord.nix
│   │   ├── adapters/            # Application-specific theme adapters
│   │   │   ├── wezterm.nix
│   │   │   ├── neovim.nix
│   │   │   └── firefox.nix
│   │   ├── presets/
│   │   │   └── transparency.nix
│   │   └── default.nix          # Theme system exports
│   ├── values/                  # Values schema (will add appearance mode, font)
│   │   └── default.nix
│   └── validation/              # Validators (will add theme validators)
│       └── default.nix
├── home/
│   └── configurations/          # Application configs (will ensure theme propagation)
│       ├── wezterm/
│       ├── neovim/
│       ├── firefox/
│       └── zsh/
└── darwin/
    └── packages/
        └── fonts.nix            # Font package management (may need enhancement)

values.nix                       # User configuration (will add appearance, font options)
```

**Structure Decision**: Nix system configuration with existing modular theme system. This is not a traditional src/tests structure but a Nix module hierarchy. All changes enhance existing `modules/lib/theme/` infrastructure, update palette definitions to support light/dark variants, add appearance mode to values schema, and ensure application adapters properly propagate theme changes.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No complexity violations - all gates pass. This feature enhances existing infrastructure without adding new architectural components.
