# Quick Reference: Nix Files Plan

**Full Plan**: See `NIX_FILES_COMPREHENSIVE_PLAN.md` (1695 lines)

---

## By File Location

### Root
- **flake.nix** - 114 lines - 🔴 CRITICAL - Root entry point

### Flake Configuration (6 files)
- inputs.nix - 40 lines - 🟡 HIGH - Pin versions
- hosts.nix - 32 lines - 🟡 HIGH - Host definitions  
- builders.nix - 140 lines - 🟡 HIGH - Nix builders
- shared-values.nix - 7 lines - 🟢 LOW - Values import
- bootstrap.nix - 5 lines - 🟢 LOW - Setup helper

### Darwin System (19 files)
- **default.nix** - 14 lines - Root aggregator
- **home-manager.nix** - 32 lines - ✅ STANDARDIZED
- **configurations/** - 18 modules (5-182 lines)
  - 🔴 CRITICAL: aerospace (182), sketchybar (93), stylix (105)
  - 🟡 HIGH: finder, environment, borders, nix, ollama, op
  - 🟢 LOW: keyboard, hostname, system, user, security, dock
- **home/** - Platform-specific macOS configs
  - firefox (179 lines) - ✅ Uses impl.nix
  - hammerspoon (18 lines)
  - sketchybar (53 lines)
- **packages/** - 84 lines Homebrew config

### NixOS System (38 files)  
- **default.nix** - 9 lines - Root aggregator
- **home-manager.nix** - 42 lines - ✅ STANDARDIZED
- **configurations/** - 23 modules (3-98 lines)
  - 🔴 CRITICAL: boot, security, hardware
  - 🟡 HIGH: audio, display (76), gpu, networking
  - **display/** - 4 files (compositor, login, niri)
- **home/** - Platform-specific Linux configs
  - nemo (33 lines) - File manager
- **packages/** - 98 lines Nixpkgs config

### Home Manager (76 files)
- **default.nix** - 82 lines - Base configuration
- **configurations/default.nix** - 38 lines - Aggregator
- **Simple modules** (<30 lines) - 13 files
  - bat, btop, carapace, colima, dircolors, direnv, eza, fd, hushlogin, vivid, zoxide, editorconfig
- **Medium** (30-100 lines) - 8 files
  - fzf, k9s, kubectl, macchina, omp, onepassword, ssh, utils
- **Complex** (100+ OR has impl.nix) - 6 files
  - atuin (impl.nix) - 104 total
  - git (3 config files) - 275 total
  - helix - 735 lines (🔴 NEEDS REFACTOR)
  - llm (6 configs + prompts) - 600+ total
  - neovim (impl.nix + lua/) - 200+ total
  - wezterm (impl.nix + lua/) - 250+ total
- **Very Large**:
  - zsh - 239 lines
  - nushell - 131 lines

### Home Packages (20 files)
- **default.nix** - 15 lines - Aggregator
- **nixpkgs/default.nix** - 160 lines - Main packages
- **Language managers** (7 groups):
  - Node (npm, yarn) - 40 + 49 lines
  - Python (pipx, uvx) - 37 + 36 lines  
  - Cargo - 36 lines
  - Go - 56 lines
  - GitHub CLI - 44 lines
  - Kubectl - 25 lines
  - Vet - 29 lines

### Shared Library (29 files - CRITICAL)
- **default.nix** - 28 lines - ✅ DOCUMENTED with groups
- **Theme System** (348 + 600+ lines)
  - 11 color palettes
  - 6 app adapters (including firefox 816 lines)
  - Core: types, utils, validators, normalizer
  - 🔴 CRITICAL - Affects all visual apps
- **Platform** - 135 lines - 🔴 CRITICAL
- **Values Schema** - 324 lines - 🔴 CRITICAL  
- **Shell Utils** - 70 lines
- **Paths/XDG** - 137 lines
- **Packages** - 88 lines
- **Modules** - 135 lines

### Overlays (2 files)
- default.nix - 8 lines - Aggregator
- packages.nix - 45 lines - Overrides

---

## By Risk Level

### 🔴 CRITICAL (Handle With Care)
- flake.nix - Root orchestrator
- modules/shared/lib/values/default.nix - Validates all config
- modules/shared/lib/theme/default.nix - All visual theming
- modules/shared/lib/platform/default.nix - System detection
- modules/darwin/default.nix - Darwin system root
- modules/nixos/default.nix - NixOS system root
- modules/home/default.nix - Home-manager root
- modules/home/configurations/helix/default.nix - 735 lines, needs refactor

### 🟡 HIGH (Review Changes)
- All flake/* except bootstrap and shared-values
- All darwin/configurations/* (system settings)
- All nixos/configurations/* (system settings)
- Home-manager: git, neovim, wezterm, zsh, nushell, llm
- All home/packages/*
- All shared/lib/theme/* (except default.nix)
- Overlays/packages.nix

### 🟢 LOW (Safe To Modify)
- flake/bootstrap.nix - Setup helper
- flake/shared-values.nix - Simple import
- overlays/default.nix - Aggregator
- Simple home configs (<30 lines)
- Platform-specific home/darwin/* and home/nixos/*

---

## By Category

### Entry Points (Must Never Break)
1. flake.nix
2. modules/darwin/default.nix
3. modules/nixos/default.nix
4. modules/home/default.nix
5. modules/shared/lib/default.nix

### Schema & Validation
- modules/shared/lib/values/default.nix - Config validation
- modules/shared/lib/theme/core/validators.nix - Color validation
- modules/shared/lib/theme/core/types.nix - Type system

### Configuration (Apply Values)
- modules/shared/lib/theme/core/palette-normalizer.nix
- modules/shared/lib/values/* (define schemas)

### System Setup (Darwin)
- modules/darwin/configurations/aerospace - WM
- modules/darwin/configurations/sketchybar - Status bar
- modules/darwin/configurations/stylix - Theme
- modules/darwin/packages/homebrew.nix - Package management

### System Setup (NixOS)
- modules/nixos/configurations/boot - Boot loader
- modules/nixos/configurations/hardware - Drivers
- modules/nixos/configurations/display - Display server
- modules/nixos/packages/nixpkgs.nix - Package management

### User Environment
- modules/home/default.nix - Base setup
- modules/home/configurations/zsh - Main shell
- modules/home/configurations/neovim - Editor
- modules/home/configurations/git - VCS

### Appearance
- modules/shared/lib/theme/* - All theming
- modules/home/configurations/helix - Editor theme
- modules/home/configurations/wezterm - Terminal theme
- modules/home/configurations/firefox - Browser theme

---

## By Complexity (For Refactoring Priority)

### Needs Refactoring (Too Large/Complex)
1. 🔴 helix/default.nix (735 lines) - Split into sections
2. 🟡 git/default.nix (174 lines) - Already split, but large
3. 🟡 llm/default.nix system - Complex interdependencies
4. 🟡 theme system overall - 1000+ lines combined

### Well-Organized (Good Examples)
- atuin (default.nix + impl.nix)
- neovim (default.nix + impl.nix + lua/)
- wezterm (default.nix + impl.nix + lua/)
- git (default.nix + lib.nix + config/*) - But could be cleaner

### Could Consolidate (Too Simple)
- bat, dircolors, eza, fd, zoxide, etc. - < 30 lines each
- Rationale: Directory overhead vs. simple configs
- Decision: Keep as-is (idiomatic Nix pattern)

---

## Handoff Checklist

When handing off to another LLM, provide:

- [ ] This file (quick reference)
- [ ] NIX_FILES_COMPREHENSIVE_PLAN.md (full plan)
- [ ] MODULE_STRUCTURE.md (architecture)
- [ ] AUDIT_SUMMARY.md (recent changes)
- [ ] Git repo with latest code (branch: main)
- [ ] Current commit hash (b9ce215d1)

Tasks for new agent should reference:
- Section from NIX_FILES_COMPREHENSIVE_PLAN.md
- Risk level (RED/YELLOW/GREEN)
- Affected files list
- Validation commands
- Expected outcomes

Example task:
```
TASK: Refactor helix configuration
REFERENCE: NIX_FILES_COMPREHENSIVE_PLAN.md → "modules/home/configurations/helix"
RISK: 🔴 CRITICAL
FILES: modules/home/configurations/helix/default.nix (735 lines)
ACTIONS:
  - Break into: keybindings.nix, languages.nix, theme.nix, ui.nix
  - Keep entry in default.nix importing all
VALIDATION:
  - nix fmt helix/default.nix (should pass)
  - nix eval '.#homeConfigurations.*.config.programs.helix' (no errors)
  - hx --health (all languages present)
EXPECTED: 4 files instead of 1, each < 200 lines
```

---

## Critical Files by Dependency Order

If making changes, test in this order:

1. flake.nix - Must build first
2. flake/{inputs,hosts,builders,shared-values}.nix - Build prerequisites
3. modules/shared/lib/values/default.nix - Config validation
4. modules/shared/lib/platform/default.nix - System detection
5. modules/shared/lib/default.nix - All utils available
6. modules/{darwin,nixos}/default.nix - System roots
7. modules/home/default.nix - Home-manager root
8. All other modules - Depend on above

---

## Files Changed Recently (Commit b9ce215d1)

- ✅ atuin/impl.nix (renamed from lib.nix)
- ✅ firefox/impl.nix (renamed from lib.nix)
- ✅ neovim/impl.nix (renamed from lib.nix)
- ✅ wezterm/impl.nix (renamed from lib.nix)
- ✅ atuin/default.nix (import updated)
- ✅ darwin/home-manager.nix (standardized)
- ✅ nixos/home-manager.nix (comments improved)
- ✅ nixos/home/default.nix (params cleaned)
- ✅ nixos/home/configurations/default.nix (params cleaned)
- ✅ shared/lib/default.nix (comments added)

**Status**: All changes tested and working. Build verified.

---

## Common LLM Tasks

### Fix Broken Module
1. Identify error from flake check output
2. Find file in NIX_FILES_COMPREHENSIVE_PLAN.md
3. Follow "Actions" section for that file
4. Run validation commands
5. Test build: task nix:build:lv426

### Add New Package
1. Identify package manager (cargo, pip, npm, etc)
2. Edit modules/home/packages/<manager>/default.nix
3. Add package name to list
4. Test: nix eval '.#homeConfigurations.*.config.home.packages'

### Add New Configuration
1. Create modules/home/configurations/<name>/default.nix
2. Edit modules/home/configurations/default.nix to import
3. Follow pattern from similar module
4. Test: nix eval '.#homeConfigurations.*.config.programs.<name>'

### Update Theme
1. Edit modules/shared/lib/theme/palettes/<theme>.nix
2. OR edit modules/shared/lib/theme/adapters/<app>.nix
3. Test: nix eval '.#utils.theme.getThemePalette "theme" "variant"'

### Fix Platform-Specific Issue
1. Check modules/shared/lib/platform/default.nix
2. Or check modules/darwin/*/default.nix (macOS only)
3. Or check modules/nixos/*/default.nix (Linux only)
4. Test: nix eval '.#darwinConfigurations.lv426.config' OR '.#nixosConfigurations.arrakis.config'

---

## Support Documents

- **NIX_FILES_COMPREHENSIVE_PLAN.md** - Detailed plan for every file (1695 lines)
- **MODULE_STRUCTURE.md** - Architecture and naming conventions  
- **AUDIT_SUMMARY.md** - Recent standardization work
- **AGENTS.md** - Build and deployment commands
- **README.md** - Project overview
