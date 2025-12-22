# Nix Configuration - Visual Dependency Hierarchy

This document shows which files depend on which, to help understand where changes will have ripple effects.

---

## Level 0: Pure Definitions (No Dependencies)

```
flake/inputs.nix         ← Pinned versions
flake/bootstrap.nix      ← Setup script
overlays/packages.nix    ← Package overrides

modules/shared/lib/theme/palettes/*.nix (11 files)
├── black-metal.nix
├── catppuccin.nix
├── everforest.nix
├── gruvbox.nix
├── kanagawa.nix
├── monokai.nix
├── nord.nix
├── retroism.nix
├── rose-pine.nix
├── solarized.nix
└── tokyonight.nix
```

**No changes needed**: Pure data definitions  
**Safe to modify**: Color values  
**Risk of change**: 🟢 LOW

---

## Level 1: Core Utilities (Used Everywhere)

```
modules/shared/lib/
├── values/default.nix (324 lines)          ← TYPE DEFINITIONS & SCHEMA
│   └── Validates: values.nix (external)
│
├── platform/default.nix (135 lines)        ← SYSTEM DETECTION
│   └── Used by: darwin/*, nixos/*, home/*
│
├── theme/core/
│   ├── constants.nix
│   ├── types.nix (191 lines)               ← COLOR TYPES
│   ├── validators.nix (336 lines)          ← COLOR VALIDATION
│   ├── utils.nix (399 lines)               ← COLOR TRANSFORMATIONS
│   └── palette-normalizer.nix (321 lines)  ← COLOR NORMALIZATION
│
├── theme/adapters/ (6 files)               ← APP-SPECIFIC COLORS
│   ├── firefox.nix (816 lines)
│   ├── neovim.nix
│   ├── wezterm.nix
│   ├── base16-schemes.nix
│   ├── gtk-retroism.nix
│   └── theme-names.nix
│
├── paths/default.nix (49 lines)            ← PATH HELPERS
├── xdg/default.nix (88 lines)              ← XDG SPEC
├── shell/default.nix + env.nix + aliases.nix
├── packages/lib.nix (81 lines)             ← PACKAGE UTILS
└── modules/theme.nix + validation.nix     ← NIXOS MODULE UTILS
```

**Dependency**: ↓ Everything below  
**Risk of change**: 🔴 CRITICAL  
**Test**: `nix eval '.#utils'`

---

## Level 2: Main Aggregators (Import Level 1)

```
modules/shared/lib/default.nix (28 lines)
├── imports all Level 1 utilities
└── exports as:
    ├── .platform
    ├── .paths
    ├── .xdg
    ├── .values
    ├── .theme      ← 348 lines + 600+ supporting
    ├── .shell
    ├── .packages
    └── .modules

overlays/default.nix
└── imports: overlays/packages.nix

flake/shared-values.nix
└── imports: values.nix (external file)

flake/hosts.nix (32 lines)
└── references: modules/darwin/*, modules/nixos/*
```

**Dependency**: Depends on Level 1  
**Used by**: Level 3+  
**Risk of change**: 🔴 CRITICAL

---

## Level 3: System Roots (Import Level 1-2)

```
flake.nix (114 lines) - ROOT ENTRY
├── inputs: flake/inputs.nix
├── builders: flake/builders.nix
├── hosts: flake/hosts.nix
├── overlays: overlays/default.nix
└── outputs:
    ├── darwinConfigurations
    │   └── imports: modules/darwin/default.nix
    │
    ├── nixosConfigurations
    │   └── imports: modules/nixos/default.nix
    │
    └── homeConfigurations
        └── imports: modules/home/default.nix
```

**Dependency**: Depends on Levels 1-2 + external inputs  
**Used by**: Users applying system  
**Risk of change**: 🔴 CRITICAL

---

## Level 4: Platform System Roots

### Darwin System

```
modules/darwin/default.nix (14 lines)
├── imports shared/lib/default.nix (via flake)
├── imports home-manager.nix
│   └── home-manager.nix (32 lines) ✅ STANDARDIZED
│       ├── imports ../home (shared home config)
│       └── imports ./home (darwin-specific home config)
│
├── imports configurations/default.nix
│   ├── aerospace (182 lines)        🔴 CRITICAL WM
│   ├── borders (19 lines)           🟡 HIGH
│   ├── builders (26 lines)          🟡 HIGH
│   ├── dock (13 lines)              🟢 LOW
│   ├── environment (22 lines)       🟡 HIGH
│   ├── finder (33 lines)            🟡 HIGH
│   ├── hostname (7 lines)           🟢 LOW
│   ├── keyboard (5 lines)           🟢 LOW
│   ├── nix (12 lines)               🟡 HIGH
│   ├── ollama (19 lines)            🟡 HIGH
│   ├── op (12 lines)                🟢 LOW
│   ├── security (11 lines)          🟢 LOW
│   ├── sketchybar (93 lines)        🔴 CRITICAL STATUS BAR
│   ├── stylix (105 lines)           🔴 CRITICAL THEME
│   ├── system (10 lines)            🟢 LOW
│   ├── tailscale (16 lines)         🟡 HIGH
│   └── user (10 lines)              🟢 LOW
│
└── imports packages/default.nix
    └── packages/homebrew.nix (84 lines) 🟡 HIGH
```

### NixOS System

```
modules/nixos/default.nix (9 lines)
├── imports shared/lib/default.nix (via flake)
├── imports home-manager.nix
│   └── home-manager.nix (42 lines) ✅ STANDARDIZED
│       ├── imports ../home (shared home config)
│       └── imports ./home (linux-specific home config)
│
├── imports configurations/default.nix
│   ├── audio (58 lines)             🟡 HIGH
│   ├── boot (18 lines)              🔴 CRITICAL
│   ├── compat (12 lines)            🟡 HIGH
│   ├── display/
│   │   ├── default.nix (7 lines)
│   │   ├── compositor.nix (10 lines) 🟡 HIGH
│   │   ├── login.nix (76 lines)     🟡 HIGH
│   │   └── niri.nix (5 lines)       🟢 LOW
│   ├── firewall (19 lines)          🟡 HIGH
│   ├── gaming (29 lines)            🟡 HIGH
│   ├── gpu (18 lines)               🟡 HIGH
│   ├── hardware (36 lines)          🔴 CRITICAL
│   ├── hostname (8 lines)           🟢 LOW
│   ├── locale (15 lines)            🟡 HIGH
│   ├── networking (27 lines)        🟡 HIGH
│   ├── nix (33 lines)               🔴 CRITICAL
│   ├── security (33 lines)          🔴 CRITICAL
│   ├── services (8 lines)           🟢 LOW
│   ├── stylix (45 lines)            🔴 CRITICAL THEME
│   ├── system (3 lines)             🟢 LOW
│   ├── tailscale (13 lines)         🟡 HIGH
│   ├── user (30 lines)              🟡 HIGH
│   ├── virtualisation (11 lines)    🟡 HIGH
│   └── xdg (36 lines)               🟡 HIGH
│
└── imports packages/default.nix
    └── packages/nixpkgs.nix (98 lines) 🟡 HIGH
```

---

## Level 5: Home-Manager Base (Import System Roots + Level 1)

```
modules/home/default.nix (82 lines)
├── imports shared/lib/default.nix (via flake)
├── sets XDG paths
├── sets session variables
└── imports configurations/default.nix
    └── See Level 6

modules/home/packages/default.nix (15 lines)
└── imports language managers:
    ├── nixpkgs/default.nix (160 lines)   🟡 HIGH
    ├── cargo/ (36 lines)                 🟡 HIGH
    ├── gh/ (44 lines)                    🟡 HIGH
    ├── go/ (56 lines)                    🟡 HIGH
    ├── kubectl/ (25 lines)               🟡 HIGH
    ├── node/ (40 + npm/yarn)             🟡 HIGH
    ├── python/ (37 + pipx/uvx)           🟡 HIGH
    └── vet/ (29 lines)                   🟢 LOW
```

---

## Level 6: Home Configurations (Import Level 5 + Shared Lib)

### Simple Modules (< 30 lines)
```
modules/home/configurations/
├── ast-grep (202 lines)
├── bat (11 lines)
├── btop (13 lines)
├── carapace (10 lines)
├── colima (5 lines)
├── dircolors (27 lines)
├── direnv (12 lines)
├── editorconfig (41 lines)
├── eza (17 lines)
├── fd (26 lines)
├── hushlogin (5 lines)
├── vivid (15 lines)
└── zoxide (12 lines)

All 🟢 LOW risk - Can modify independently
```

### Medium Modules (30-100 lines)
```
├── fzf (43 lines)
├── k9s (58 lines)
├── kubectl (46 lines)
├── macchina (167 lines)
├── omp (103 lines)
├── onepassword (35 lines)
├── ssh (35 lines)
└── utils (30 lines)

All 🟡 HIGH - Review before change
```

### Complex Modules (has impl.nix OR > 100 lines)
```
├── atuin
│   ├── default.nix (48 lines)
│   └── impl.nix (56 lines)
│
├── git
│   ├── default.nix (174 lines)
│   ├── delta-lib.nix (24 lines)
│   └── config/
│       ├── gh-dash.nix (196 lines)
│       ├── gitignore.nix (52 lines)
│       └── lazygit.nix (79 lines)
│
├── helix (735 lines)
│   └── 🔴 CRITICAL - NEEDS REFACTOR
│
├── llm
│   ├── default.nix (13 lines)
│   ├── config/ (6 files, 435 lines total)
│   │   ├── amp.nix (60 lines)
│   │   ├── claude.nix (62 lines)
│   │   ├── copilot.nix (105 lines)
│   │   ├── cursor.nix (59 lines)
│   │   ├── goose.nix (50 lines)
│   │   └── opencode.nix (99 lines)
│   ├── prompts/ (8 files, 578 lines total)
│   │   ├── agent-organizer.nix (85 lines)
│   │   ├── ai-engineer.nix (65 lines)
│   │   ├── api-documenter.nix (67 lines)
│   │   ├── backend-architect.nix (41 lines)
│   │   ├── context-manager.nix (66 lines)
│   │   ├── frontend-developer.nix (68 lines)
│   │   ├── platform-engineer.nix (79 lines)
│   │   └── typescript-expert.nix (47 lines)
│   └── shared/ (5 files, 649 lines total)
│       ├── common.nix (342 lines)
│       ├── directives.nix (65 lines)
│       ├── lsp.nix (91 lines)
│       ├── mcp-servers.nix (42 lines)
│       ├── prompts.nix (35 lines)
│       └── writable-configs.nix (116 lines)
│
├── neovim
│   ├── default.nix (56 lines)
│   ├── impl.nix (86 lines)
│   ├── init.lua
│   ├── queries/
│   └── lua/ (plugin directories)
│
├── wezterm
│   ├── default.nix (27 lines)
│   ├── impl.nix (129 lines)
│   ├── wezterm.lua
│   ├── colors/
│   └── lua/ (event handlers)
│
├── zsh (239 lines)
│
└── nushell (131 lines)

All 🟡 HIGH - Test changes carefully
```

### Platform-Specific Modules

```
darwin/home/configurations/
├── firefox (179 lines + 489 impl.nix)    🟡 HIGH
├── hammerspoon (18 lines)                🟡 HIGH
├── sketchybar (53 lines)                 🟡 HIGH
└── packages.nix (10 lines)               🟢 LOW

nixos/home/configurations/
└── nemo (33 lines)                       🟢 LOW
```

---

## Change Ripple Effects

### If you change Level 1 (Core Utilities)

Changes to these files will affect **everything**:
- `shared/lib/values/default.nix` - All config validation
- `shared/lib/platform/default.nix` - All system detection
- `shared/lib/theme/` system - All color/themes

**Test path**: 
```bash
nix eval '.#darwinConfigurations.lv426.config'  # Darwin
nix eval '.#nixosConfigurations.arrakis.config'  # NixOS
nix eval '.#homeConfigurations.*.config'         # Home-Manager
task nix:build:lv426                             # Full build
```

---

### If you change a System Configuration (Darwin/NixOS)

Changes to darwin/configurations/* or nixos/configurations/* will affect:
- That specific system only
- Related home-manager setup

**Test path**:
```bash
task nix:build:lv426      # For Darwin changes
task nix:build:arrakis    # For NixOS changes
```

---

### If you change a Home Configuration

Changes to home/configurations/* will affect:
- That specific tool/app only
- Potentially other tools that depend on it (e.g., shell + git)

**Test path**:
```bash
nix eval ".#homeConfigurations.*.config.programs.<tool>"
```

---

### If you change a Package List

Changes to home/packages/* or darwin/packages/homebrew.nix:
- That specific package manager
- System startup/speed (install time)

**Test path**:
```bash
nix eval '.#homeConfigurations.*.config.home.packages' | wc -w
```

---

## Dependency Matrix

| Change Affects... | If you change... | Rebuild needed | Test with... |
|---|---|---|---|
| Everything | shared/lib/ | ✅ FULL | nix flake check |
| Everything | flake.nix | ✅ FULL | task nix:build:all |
| Darwin only | modules/darwin/ | ✅ DARWIN | task nix:build:lv426 |
| NixOS only | modules/nixos/ | ✅ NIXOS | task nix:build:arrakis |
| Home-Manager | modules/home/ | ✅ HOME | nix eval .#homeConfigurations |
| Single tool | home/configs/<tool>/ | ✅ REBUILD | nix eval .#homeConfigurations.*.config.programs.<tool> |
| Themes only | shared/lib/theme/ | ✅ VISUAL | Visual inspection |
| Packages only | home/packages/ | 🔄 SOURCE | `nix eval .#homeConfigurations.*.config.home.packages` |

---

## Safe Parallel Changes

These can be changed in parallel without conflicts:

- All `home/configurations/simple/` modules (bat, eza, fd, etc.)
- All `home/packages/*` except nixpkgs/default.nix
- All `darwin/configurations/*` (except one affecting another)
- All `nixos/configurations/*` (except one affecting another)
- All `shared/lib/theme/palettes/*` (individual colors)

---

## High-Risk Change Sequences

**Sequence 1: System Reconfiguration**
1. Modify shared/lib/platform/default.nix
2. Update darwin/default.nix
3. Update nixos/default.nix
4. Test: nix flake check && task nix:build:all

**Sequence 2: Theme System Overhaul**
1. Modify shared/lib/theme/core/types.nix
2. Update shared/lib/theme/core/validators.nix
3. Update all adapters
4. Update all configs that use theme
5. Test: nix eval '.#utils.theme' then visual inspection

**Sequence 3: Home-Manager Structure Change**
1. Modify modules/home/default.nix
2. Verify modules/home/configurations/default.nix
3. Update all configs if structure changed
4. Test: nix eval '.#homeConfigurations.*.config'

---

## Files That Must NEVER Break

If any of these files fails to evaluate, nothing works:

1. **flake.nix** - Root entry point
2. **flake/inputs.nix** - Pinned versions
3. **modules/shared/lib/values/default.nix** - Config schema
4. **modules/shared/lib/platform/default.nix** - System detection
5. **modules/shared/lib/default.nix** - Utility aggregator
6. **modules/darwin/default.nix** - Darwin system root
7. **modules/nixos/default.nix** - NixOS system root
8. **modules/home/default.nix** - Home-manager root

**Protection strategy**:
- Keep these files < 50 lines if possible
- Add extensive comments
- Never break imports
- Always test: `nix flake check` before pushing

---

## Color: Risk vs Complexity

```
LOW RISK          MEDIUM RISK       HIGH RISK         CRITICAL RISK
(Safe to change)  (Review needed)   (Test after)      (VERY CAREFUL)

Simple mods       Medium modules    Complex modules   Core utilities
(<30 lines)       (30-100)          (100+)            (Level 1-2)

Simple packages   Shell configs     System configs    Platform/Theme
Theme colors      Git configs       Helix, Neovim    Values schema
                                    LLM configs      flake.nix
```

When in doubt: **Ask before changing anything in Level 1-2 or touching file lists in Level 3-4.**
