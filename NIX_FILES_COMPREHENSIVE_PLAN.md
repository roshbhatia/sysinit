# Comprehensive Nix Files Plan & Audit

**Total Files**: 182 .nix files  
**Date**: Dec 21, 2025  
**Purpose**: Provide specific actions and validation steps for every Nix file in the repository

---

## Table of Contents
1. [Flake Root & Configuration](#flake-root--configuration)
2. [Darwin System (19 files)](#darwin-system)
3. [NixOS System (38 files)](#nixos-system)
4. [Home Manager Configurations (76 files)](#home-manager-configurations)
5. [Home Manager Packages (20 files)](#home-manager-packages)
6. [Shared Library (29 files)](#shared-library)
7. [Overlays (2 files)](#overlays)
8. [Validation & Testing](#validation--testing)
9. [Handoff Instructions](#handoff-instructions)

---

## Flake Root & Configuration

### flake.nix (114 lines) - ROOT ENTRY POINT

**Current State**: Main flake configuration orchestrating entire system

**Actions**:
- [ ] Verify all inputs are used (check for dead inputs)
- [ ] Ensure all outputs match host configurations (lv426=Darwin, arrakis=NixOS)
- [ ] Check that extraSpecialArgs includes all required values (lib, pkgs, utils, inputs, values)
- [ ] Verify NixOS and Darwin configs reference correct modules
- [ ] Ensure bootstrap flake included if needed

**Validation**:
```bash
nix flake check  # Verify flake is valid
nix flake show   # Verify all outputs present
grep -c "outputs" flake.nix  # Should have exactly 1 outputs definition
```

**Dependencies**: 
- flake/inputs.nix
- flake/builders.nix
- flake/hosts.nix
- All system modules

**Risk Level**: 🔴 CRITICAL - Changes here affect entire system

---

### flake/inputs.nix (40 lines)

**Current State**: Defines all flake inputs (nixpkgs, darwin, home-manager, etc.)

**Actions**:
- [ ] Review each input for correct branch/revision
- [ ] Ensure inputs.self is present for flake-utils
- [ ] Verify all inputs are actually used in flake.nix
- [ ] Check for deprecated input versions
- [ ] Ensure follows logic is correct (e.g., home-manager follows nixpkgs)

**Validation**:
```bash
nix flake check  # Catches invalid inputs
# For each input, verify used in flake.nix:
grep "inputs\." /Users/rshnbhatia/github/personal/roshbhatia/sysinit/flake.nix
```

**Dependencies**: None (pure input definitions)

**Risk Level**: 🟡 HIGH - Pinned versions, changes affect reproducibility

---

### flake/shared-values.nix (7 lines)

**Current State**: Shared values imported across all configurations

**Actions**:
- [ ] Verify values.nix file exists and is valid
- [ ] Check that import path is correct
- [ ] Ensure all required fields documented in values.nix schema

**Validation**:
```bash
nix eval .#utils  # Test that values import works
```

**Dependencies**: 
- modules/shared/lib/values/default.nix

**Risk Level**: 🟢 LOW - Simple import

---

### flake/bootstrap.nix (5 lines)

**Current State**: Bootstrap helper for initial setup

**Actions**:
- [ ] Document purpose and when to use
- [ ] Verify references to setup scripts are correct
- [ ] Add comments if unclear

**Validation**:
```bash
source flake/bootstrap.nix  # Should not error
```

**Risk Level**: 🟢 LOW

---

### flake/builders.nix (140 lines)

**Current State**: Custom Nix builders for system setup

**Actions**:
- [ ] Review each builder function for correctness
- [ ] Verify all shell scripts are executed correctly
- [ ] Check that builders don't have side effects beyond intended scope
- [ ] Ensure error handling is proper (set -euo pipefail)
- [ ] Review logging and output capture

**Validation**:
```bash
# For each builder, test its logic:
nix eval .#builders  # Should work without errors
# Check shell script syntax:
shellcheck flake/builders.nix 2>/dev/null || nix fmt flake/builders.nix
```

**Dependencies**: 
- hack/fmt-nix-check.sh (referenced)
- hack/nix-build.sh (referenced)

**Risk Level**: 🟡 HIGH - Executes scripts

---

### flake/hosts.nix (32 lines)

**Current State**: Defines host configurations (lv426, arrakis, work)

**Actions**:
- [ ] Verify each host has correct system (aarch64-darwin, x86_64-linux)
- [ ] Ensure modules array references correct paths (modules/darwin, modules/nixos)
- [ ] Check that extraSpecialArgs contains all needed values
- [ ] Verify hostname matches actual system

**Validation**:
```bash
hostname  # Should match one of the defined hosts
# For each host, verify its modules:
ls modules/darwin && ls modules/nixos
```

**Dependencies**: 
- modules/darwin/default.nix
- modules/nixos/default.nix

**Risk Level**: 🟡 HIGH - System-specific configuration

---

## Darwin System

**Overview**: 19 files configuring macOS via nix-darwin + home-manager

### modules/darwin/default.nix (14 lines)

**Current State**: Entry point importing all Darwin configurations

**Actions**:
- [ ] Verify imports list includes all needed modules (home-manager, configurations, packages)
- [ ] Check that system.build.applications is used by flake
- [ ] Ensure no duplicate imports

**Validation**:
```bash
nix eval '.#darwinConfigurations.lv426.config'  # Should not error
```

**Dependencies**: 
- All modules/darwin/configurations/*
- modules/darwin/home-manager.nix
- modules/darwin/packages/default.nix

**Risk Level**: 🟡 HIGH

---

### modules/darwin/home-manager.nix (32 lines) - RECENTLY STANDARDIZED

**Current State**: home-manager integration for Darwin

**Actions**:
- [x] ✅ Standardized to accept inputs parameter
- [x] ✅ Added sharedModules array
- [ ] Verify extraSpecialArgs are passed correctly (utils, values, inputs)
- [ ] Test that home-manager builds successfully
- [ ] Verify user.username from values is used correctly

**Validation**:
```bash
nix eval '.#darwinConfigurations.lv426.config.home-manager'
```

**Dependencies**: 
- modules/home/default.nix
- modules/darwin/home/default.nix

**Risk Level**: 🟡 HIGH

---

### modules/darwin/configurations/default.nix (22 lines)

**Current State**: Aggregates all Darwin system configurations

**Actions**:
- [ ] Verify all 18 configuration modules are imported
- [ ] Check imports are in alphabetical order (for consistency)
- [ ] Ensure no configs are missing from the list

**Validation**:
```bash
ls modules/darwin/configurations/ | grep -v default.nix | sort > /tmp/expected.txt
grep "\./" modules/darwin/configurations/default.nix | sed 's/.*\/\([^/]*\).*/\1/' | sort > /tmp/actual.txt
diff /tmp/expected.txt /tmp/actual.txt
```

**Dependencies**: All modules/darwin/configurations/* directories

**Risk Level**: 🟢 LOW

---

### Darwin Configuration Modules (17 files - 5 to 182 lines)

Each configuration module follows the pattern: `modules/darwin/configurations/<name>/default.nix`

**List**:
1. aerospace (182 lines) - Window manager configuration
2. borders (19 lines) - Border styling
3. builders (26 lines) - Nix builder configuration
4. dock (13 lines) - Dock configuration
5. environment (22 lines) - System environment variables
6. finder (33 lines) - Finder configuration
7. hostname (7 lines) - System hostname
8. keyboard (5 lines) - Keyboard settings
9. nix (12 lines) - Nix daemon configuration
10. ollama (19 lines) - LLM service configuration
11. op (12 lines) - 1Password CLI configuration
12. security (11 lines) - Security settings
13. sketchybar (93 lines) - Status bar configuration
14. stylix (105 lines) - Theme configuration
15. system (10 lines) - System settings
16. tailscale (16 lines) - VPN configuration
17. user (10 lines) - User settings

**Common Actions** (for all 17):
- [ ] Verify uses only Darwin-compatible options (no nixos.*)
- [ ] Check that all enabled options are actually needed
- [ ] Ensure no hardcoded paths (use lib.getExe or similar)
- [ ] Verify error messages are clear
- [ ] Check for out-of-store symlinks (mkOutOfStoreSymlink)

**Complexity-Specific**:

**Large (>50 lines)**: aerospace, sketchybar, stylix
- [ ] Break into logical subsections with comments
- [ ] Consider extracting helper functions to separate file
- [ ] Verify no dead code

**Medium (20-50 lines)**: finder, environment, borders, ollama, nix, op
- [ ] Verify single responsibility
- [ ] Check parameter usage

**Small (<20 lines)**: hostname, keyboard, system, user, security, dock, tailscale
- [ ] Ensure they're not missing any obvious options
- [ ] Consider if should be consolidated with similar configs

**Validation** (for all):
```bash
nix eval '.#darwinConfigurations.lv426.config.system' 2>&1 | grep -i error
```

**Risk Level**: 
- 🔴 CRITICAL: aerospace, sketchybar, stylix (many options)
- 🟡 HIGH: finder, environment, borders, ollama
- 🟢 LOW: others

---

### modules/darwin/packages/default.nix (6 lines)

**Current State**: Simple aggregator for package configurations

**Actions**:
- [ ] Verify homebrew.nix import is correct
- [ ] Ensure no unused imports

**Validation**:
```bash
nix eval '.#darwinConfigurations.lv426.config.environment.systemPackages' | wc -w
```

**Dependencies**: modules/darwin/packages/homebrew.nix

**Risk Level**: 🟢 LOW

---

### modules/darwin/packages/homebrew.nix (84 lines)

**Current State**: Homebrew package management for macOS

**Actions**:
- [ ] Review each cask/package for necessity
- [ ] Verify tap sources are trusted
- [ ] Check that no deprecated packages are listed
- [ ] Ensure system versions match values.nix (if version-specific)
- [ ] Verify brews, casks, and taps are all used/correct

**Validation**:
```bash
# Check syntax
nix fmt modules/darwin/packages/homebrew.nix
# Verify brew is configured:
which brew  # Should exist on macOS
```

**Dependencies**: values.nix (for decisions)

**Risk Level**: 🟡 HIGH - Installs packages

---

### modules/darwin/home/default.nix (5 lines)

**Current State**: Platform-specific home-manager entry for Darwin

**Actions**:
- [ ] Verify imports platform-specific home configs
- [ ] Ensure no unused imports

**Validation**:
```bash
nix eval '.#darwinConfigurations.lv426.home-manager'
```

**Dependencies**: modules/darwin/home/configurations/default.nix

**Risk Level**: 🟢 LOW

---

### modules/darwin/home/configurations/default.nix (8 lines)

**Current State**: Aggregates macOS-specific home configs

**Actions**:
- [x] ✅ Verified contains firefox, hammerspoon, sketchybar
- [ ] Confirm these are macOS-only (true for all three)
- [ ] Check packages.nix is for system packages

**Validation**:
```bash
# Verify these tools are macOS-only:
grep -l "hammerspoon\|sketchybar" /etc/os-release  # Should not exist on Linux
```

**Risk Level**: 🟢 LOW

---

### Darwin Home Configurations (3 files)

**1. modules/darwin/home/configurations/firefox/default.nix (179 lines)**

**Current State**: macOS Firefox configuration

**Actions**:
- [ ] Verify all extensions are still maintained/available
- [ ] Check userChrome.css paths are correct
- [ ] Ensure no hardcoded usernames
- [ ] Verify policies/prefs match current Firefox version

**Validation**:
```bash
ls ~/.mozilla/firefox/*/  # Should exist if Firefox installed
```

**Dependencies**: modules/darwin/home/configurations/firefox/impl.nix

**Risk Level**: 🟡 HIGH

---

**2. modules/darwin/home/configurations/hammerspoon/default.nix (18 lines)**

**Current State**: macOS automation framework configuration

**Actions**:
- [ ] Verify hammerspoon.lua references exist
- [ ] Check symlinks are correctly set up
- [ ] Ensure all required Lua dependencies are installed

**Validation**:
```bash
ls ~/.hammerspoon/init.lua  # Should exist if enabled
```

**Dependencies**: hammerspoon Lua config files

**Risk Level**: 🟡 HIGH

---

**3. modules/darwin/home/configurations/sketchybar/default.nix (53 lines)**

**Current State**: macOS status bar configuration

**Actions**:
- [ ] Verify all plugins are available
- [ ] Check color theme references match values.nix
- [ ] Ensure all Lua modules are imported
- [ ] Verify font selections are available on system

**Validation**:
```bash
brew list sketchybar  # Should be installed
```

**Risk Level**: 🟡 HIGH

---

### modules/darwin/home/configurations/packages.nix (10 lines)

**Current State**: macOS home-manager package imports

**Actions**:
- [ ] Verify all imports are for macOS-only packages
- [ ] Check for conflicts with homebrew

**Validation**:
```bash
nix eval '.#darwinConfigurations.lv426.home.packages' | head -20
```

**Risk Level**: 🟢 LOW

---

## NixOS System

**Overview**: 38 files configuring Linux via NixOS + home-manager

### modules/nixos/default.nix (9 lines)

**Current State**: Entry point importing all NixOS configurations

**Actions**:
- [ ] Verify imports include configurations, home-manager, packages
- [ ] Ensure no duplicate imports
- [ ] Check all needed subsystems are present

**Validation**:
```bash
nix eval '.#nixosConfigurations.arrakis.config'  # Should not error
```

**Dependencies**: 
- All modules/nixos/configurations/*
- modules/nixos/home-manager.nix
- modules/nixos/packages/default.nix

**Risk Level**: 🟡 HIGH

---

### modules/nixos/home-manager.nix (42 lines) - RECENTLY STANDARDIZED

**Current State**: home-manager integration for NixOS

**Actions**:
- [x] ✅ Standardized to include inputs parameter
- [x] ✅ Improved comments on stylix target overrides
- [ ] Verify sharedModules apply correctly
- [ ] Test that stylix targets (mako, waybar) work on login
- [ ] Ensure no conflicts with system-level theme config

**Validation**:
```bash
nix eval '.#nixosConfigurations.arrakis.config.home-manager'
```

**Dependencies**: 
- modules/home/default.nix
- modules/nixos/home/default.nix

**Risk Level**: 🟡 HIGH

---

### modules/nixos/configurations/default.nix (23 lines)

**Current State**: Aggregates all NixOS system configurations

**Actions**:
- [ ] Verify all 24 configuration modules are imported
- [ ] Check imports are in alphabetical order
- [ ] Ensure no duplicates

**Validation**:
```bash
ls modules/nixos/configurations/ | grep -v default.nix | wc -l  # Should be 24
```

**Dependencies**: All modules/nixos/configurations/* directories

**Risk Level**: 🟢 LOW

---

### NixOS Configuration Modules (22 files - 3 to 98 lines)

**List**:
1. audio (58 lines) - Audio system configuration
2. boot (18 lines) - Boot loader and kernel
3. compat (12 lines) - Compatibility layers
4. display (multiple files) - Display server (X11/Wayland)
   - default.nix (7 lines)
   - compositor.nix (10 lines)
   - login.nix (76 lines)
   - niri.nix (5 lines)
5. firewall (19 lines) - Firewall rules
6. gaming (29 lines) - Gaming packages/config
7. gpu (18 lines) - GPU drivers and config
8. hardware (36 lines) - Hardware detection and drivers
9. hostname (8 lines) - System hostname
10. locale (15 lines) - Localization and time
11. networking (27 lines) - Network configuration
12. nix (33 lines) - Nix daemon and package manager
13. packages (1 line aggregator) - Package management
14. security (33 lines) - Security configuration
15. services (8 lines) - System services
16. stylix (45 lines) - Theme configuration
17. system (3 lines) - System-level settings
18. tailscale (13 lines) - VPN client
19. user (30 lines) - User account setup
20. virtualisation (11 lines) - VM and container support
21. xdg (36 lines) - XDG base directory spec
22. nemo (33 lines in home) - Linux file manager

**Common Actions** (for all):
- [ ] Verify no Darwin-specific options (no launchd, Homebrew, etc.)
- [ ] Check all options are valid for current NixOS version
- [ ] Ensure hardware-specific options are conditionally enabled
- [ ] Review system service startup requirements
- [ ] Verify security implications of configuration choices

**Complexity-Specific**:

**Very Large (>70 lines)**: audio (58), login.nix (76)
- [ ] Break into logical subsections
- [ ] Consider extracting options to separate files
- [ ] Add detailed comments for complex configurations

**Large (40-70 lines)**: hardware (36), xdg (36), security (33), nix (33), user (30), gaming (29), networking (27)
- [ ] Verify internal structure is clear
- [ ] Check for options that could be extracted

**Medium (18-40 lines)**: boot, display/default, gpu, locale, compat, tailscale, services, stylix
- [ ] Verify single responsibility
- [ ] Check parameter usage

**Small (<18 lines)**: hostname, firewall, virtualisation, niri, services, system, packages
- [ ] Verify they're complete (not missing obvious options)
- [ ] Consider if should be consolidated

**Validation**:
```bash
nix eval '.#nixosConfigurations.arrakis.config' 2>&1 | grep -i error
nixos-option system.stateVersion  # Verify system version is set
```

**Risk Level**: 
- 🔴 CRITICAL: boot, security, hardware, nix (system integrity)
- 🟡 HIGH: audio, display, gpu, networking, services
- 🟢 LOW: others

---

### Display Subsystem (4 files)

**Breakdown**:

**display/default.nix (7 lines)**
- Aggregates: compositor, login, possibly niri
- **Action**: Verify correct compositor is imported for target system

**display/compositor.nix (10 lines)**
- Likely enables X11 or Wayland
- **Action**: Verify matches display/login configuration

**display/login.nix (76 lines)**
- Display manager (SDDM, LightDM, etc.) configuration
- **Actions**:
  - [ ] Verify theme matches stylix configuration
  - [ ] Check keyboard layout
  - [ ] Ensure QT/GTK settings are applied

**display/niri.nix (5 lines)**
- Niri window manager (if used)
- **Action**: Verify this is the intended WM; check for conflicts with other WMs

---

### modules/nixos/packages/default.nix (7 lines)

**Current State**: Package aggregator

**Actions**:
- [ ] Verify nixpkgs.nix import is correct
- [ ] Check no unused imports

**Dependencies**: modules/nixos/packages/nixpkgs.nix

**Risk Level**: 🟢 LOW

---

### modules/nixos/packages/nixpkgs.nix (98 lines)

**Current State**: NixOS package declarations

**Actions**:
- [ ] Review each package for necessity
- [ ] Check for deprecated packages
- [ ] Verify version pins are intentional
- [ ] Ensure overlays are applied correctly
- [ ] Check for package conflicts

**Validation**:
```bash
nix eval '.#nixosConfigurations.arrakis.config.environment.systemPackages' | wc -w
```

**Risk Level**: 🟡 HIGH - Installs packages

---

### modules/nixos/home/default.nix (5 lines) - RECENTLY CLEANED

**Current State**: Platform-specific home-manager entry for NixOS

**Actions**:
- [x] ✅ Removed unused parameters
- [ ] Verify imports are correct

**Validation**:
```bash
nix eval '.#nixosConfigurations.arrakis.home-manager'
```

**Risk Level**: 🟢 LOW

---

### modules/nixos/home/configurations/default.nix (5 lines) - RECENTLY CLEANED

**Current State**: Linux-specific home configurations

**Actions**:
- [x] ✅ Removed unused parameters
- [ ] Verify nemo import is correct
- [ ] Confirm nemo is Linux-only tool

**Risk Level**: 🟢 LOW

---

### modules/nixos/home/configurations/nemo/default.nix (33 lines)

**Current State**: Nemo file manager configuration (Linux)

**Actions**:
- [ ] Verify Nemo is installed via nixpkgs
- [ ] Check all configuration options are valid
- [ ] Ensure themes/icons match system theme

**Validation**:
```bash
nix eval '.#nixosConfigurations.arrakis.home.programs.nemo' | head -10
```

**Risk Level**: 🟢 LOW

---

## Home Manager Configurations

**Overview**: 76 files for cross-platform home configuration

### modules/home/default.nix (82 lines)

**Current State**: Cross-platform home-manager base configuration

**Actions**:
- [ ] Review all session variables for necessity
- [ ] Verify XDG paths are set correctly
- [ ] Check bash activation hook is needed
- [ ] Ensure all aliases are documented

**Validation**:
```bash
nix eval '.#homeConfigurations.*.config.home.homeDirectory'
```

**Dependencies**: 
- modules/home/configurations/default.nix
- modules/home/packages/default.nix

**Risk Level**: 🟡 HIGH

---

### modules/home/configurations/default.nix (38 lines)

**Current State**: Aggregates 34 home configuration modules

**Actions**:
- [ ] Verify all 34 modules are listed
- [ ] Check imports are alphabetical (for consistency)
- [ ] Remove any commented-out imports

**Validation**:
```bash
ls modules/home/configurations/ | grep -v default.nix | wc -l  # Should be 34
```

**Risk Level**: 🟢 LOW

---

### Home Configuration Modules - By Complexity

#### Simple Modules (< 30 lines, no subdirectories)

**Files** (13 total):
1. ast-grep (202 lines) - Tool configuration (actually complex!)
2. bat (11 lines)
3. btop (13 lines)
4. carapace (10 lines)
5. colima (5 lines)
6. dircolors (27 lines)
7. direnv (12 lines)
8. editorconfig (41 lines)
9. eza (17 lines)
10. fd (26 lines)
11. hushlogin (5 lines)
12. vivid (15 lines)
13. zoxide (12 lines)

**Common Actions**:
- [ ] Verify enable/disable flags are documented
- [ ] Check all options are from home-manager (not NixOS)
- [ ] Ensure no hardcoded paths

**Validation**:
```bash
for config in bat btop carapace colima dircolors direnv eza fd; do
  nix eval ".#homeConfigurations.user.config.programs.$config" 2>&1 | head -1
done
```

**Risk Level**: 🟢 LOW

---

#### Medium Modules (30-100 lines)

**Files** (8 total):
1. fzf (43 lines) - Fuzzy finder
2. k9s (58 lines) - Kubernetes client
3. kubectl (46 lines) - Kubernetes CLI
4. macchina (167 lines) - System info (actually larger!)
5. omp (103 lines) - Oh My Posh prompt (actually larger!)
6. onepassword (35 lines) - Password manager
7. ssh (35 lines) - SSH configuration
8. utils (30 lines) - Utilities

**Actions**:
- [ ] Review configuration options for necessity
- [ ] Check for conflicts with other tools
- [ ] Verify all referenced paths exist

**Risk Level**: 🟡 HIGH

---

#### Complex Modules (100+ lines OR has impl.nix)

**Files** (6 total):
1. **atuin** (48 lines + impl.nix 56 lines = 104 total)
   - **Actions**:
     - [ ] Verify atuin theme adapter in impl.nix works
     - [ ] Check database location is writable
     - [ ] Ensure history filtering works as intended

2. **git** (174 lines + delta-lib.nix 24 lines + 3 config files = 275 total)
   - **Actions**:
     - [ ] Review all git aliases for conflicts
     - [ ] Verify delta pager configuration is correct
     - [ ] Check lazygit config includes all features
     - [ ] Ensure gh-dash config is valid

3. **helix** (735 lines)
   - **Actions**:
     - [ ] Break into subsections if not already done
     - [ ] Verify all plugins are available
     - [ ] Check theme references match values.nix
     - [ ] Ensure keybindings don't conflict

4. **llm** (13 lines + 6 config files + prompts + shared = 600+ total)
   - **Actions**:
     - [ ] Verify all LLM clients are available
     - [ ] Check MCP servers are correctly configured
     - [ ] Ensure prompts are semantically correct
     - [ ] Test each agent prompt for clarity

5. **neovim** (56 lines + impl.nix 86 lines + lua/ = 200+ total)
   - **Actions**:
     - [ ] Verify all Lua plugins load correctly
     - [ ] Check theme application in init.lua
     - [ ] Ensure impl.nix helpers are used correctly

6. **wezterm** (27 lines + impl.nix 129 lines + lua/ = 250+ total)
   - **Actions**:
     - [ ] Verify colors are applied from theme
     - [ ] Check Lua event handlers work
     - [ ] Ensure multiplexer config is correct

---

#### Very Large/Complex Modules (detailed plans)

**modules/home/configurations/helix/default.nix (735 lines)**

**Current State**: Helix editor full configuration

**Actions** (PRIORITY):
- [ ] Split into logical sections if monolithic
- [ ] Extract theme configuration to separate file
- [ ] Extract language server definitions to separate file
- [ ] Extract keybinding definitions to separate file
- [ ] Add section comments (## Language Servers, ## Themes, ## Keys)

**Sub-actions** (if keeping as single file):
- [ ] Verify all language servers have matching language entries
- [ ] Check all referenced languages are supported
- [ ] Ensure theme name matches values.nix
- [ ] Verify keybindings don't conflict

**Validation**:
```bash
helix --version  # Should be installed
hx --health      # Should show all languages configured
```

**Risk Level**: 🔴 CRITICAL

---

**modules/home/configurations/zsh/default.nix (239 lines)**

**Current State**: Zsh shell configuration

**Actions**:
- [ ] Verify all plugins are available
- [ ] Check completion configuration
- [ ] Ensure aliases don't conflict with other tools
- [ ] Verify theme reference matches values.nix
- [ ] Check history settings

**Sub-sections**:
- [ ] Plugins section
- [ ] Completion section
- [ ] Alias section
- [ ] Theme section

**Validation**:
```bash
zsh --version  # Should be set as default shell
echo $SHELL    # Should be /run/current-system/sw/bin/zsh
```

**Risk Level**: 🟡 HIGH

---

**modules/home/configurations/nushell/default.nix (131 lines)**

**Current State**: Nu shell configuration

**Actions**:
- [ ] Verify nu installation
- [ ] Check all environment variables are set
- [ ] Verify module imports
- [ ] Check that both zsh and nu don't conflict

**Validation**:
```bash
nu --version  # Should work
nu -c "echo 'test'"  # Should execute
```

**Risk Level**: 🟡 HIGH

---

**modules/home/configurations/git/default.nix (174 lines)**

**Current State**: Git configuration

**Actions**:
- [ ] Verify user.name and user.email match values.nix
- [ ] Check all aliases are clear and documented
- [ ] Ensure delta configuration works with git
- [ ] Verify GitHub CLI (gh) is installed
- [ ] Check gitignore_global path

**Sub-components**:
- [ ] git config/gitignore.nix
- [ ] git config/gh-dash.nix (196 lines)
- [ ] git config/lazygit.nix (79 lines)
- [ ] git/delta-lib.nix (24 lines)

**Validation**:
```bash
git config --global user.name  # Should be set
git config --global diff.pager  # Should show delta
gh --version  # Should be installed
```

**Risk Level**: 🟡 HIGH

---

**modules/home/configurations/llm/default.nix (13 lines)**

**Current State**: LLM client aggregator

**Actions**:
- [ ] Verify all config files are imported
- [ ] Check all prompts are loaded
- [ ] Ensure shared utilities are available

**Sub-components** (9 files):
- **Configs** (6 files):
  - amp.nix (60 lines)
  - claude.nix (62 lines)
  - copilot.nix (105 lines)
  - cursor.nix (59 lines)
  - goose.nix (50 lines)
  - opencode.nix (99 lines)

- **Prompts** (8 files):
  - agent-organizer.nix (85 lines)
  - ai-engineer.nix (65 lines)
  - api-documenter.nix (67 lines)
  - backend-architect.nix (41 lines)
  - context-manager.nix (66 lines)
  - frontend-developer.nix (68 lines)
  - platform-engineer.nix (79 lines)
  - typescript-expert.nix (47 lines)

- **Shared** (4 files):
  - common.nix (342 lines)
  - directives.nix (65 lines)
  - lsp.nix (91 lines)
  - mcp-servers.nix (42 lines)
  - prompts.nix (35 lines)
  - writable-configs.nix (116 lines)

**Actions by file**:

**Config files** (amp, claude, copilot, cursor, goose, opencode):
- [ ] Verify API endpoints are correct
- [ ] Check authentication tokens are referenced (not hardcoded)
- [ ] Ensure all configuration options match client docs
- [ ] Verify default models are available

**Prompt files** (all agents):
- [ ] Check grammar and clarity
- [ ] Verify no hardcoded paths
- [ ] Ensure instructions are complete
- [ ] Check that examples are current

**Shared files**:
- **common.nix** (342 lines): 
  - [ ] Verify common directives are comprehensive
  - [ ] Check no duplicate definitions
  
- **directives.nix** (65 lines):
  - [ ] Verify instructions are clear
  - [ ] Check they apply to all agents
  
- **lsp.nix** (91 lines):
  - [ ] Verify language server configs
  - [ ] Check matching with neovim setup
  
- **mcp-servers.nix** (42 lines):
  - [ ] Verify MCP server endpoints
  - [ ] Check credentials/tokens are secure
  
- **prompts.nix** (35 lines):
  - [ ] Verify all prompts are referenced
  - [ ] Check no dead prompt imports
  
- **writable-configs.nix** (116 lines):
  - [ ] Verify writable config paths
  - [ ] Check permissions are correct

**Validation**:
```bash
# Test LLM configs exist
for llm in amp claude copilot cursor goose opencode; do
  [ -f "modules/home/configurations/llm/config/$llm.nix" ] || echo "Missing: $llm"
done

# Test prompts exist
ls modules/home/configurations/llm/prompts/*.nix | wc -l  # Should be 8
```

**Risk Level**: 🟡 HIGH (many interdependencies)

---

#### Editor Configurations (neovim, wezterm, firefox)

**neovim** (56 + 86 + Lua code):
- [ ] Verify Lua plugins load in correct order
- [ ] Check init.lua syntax is valid
- [ ] Ensure impl.nix helpers are used
- [ ] Verify theme application works

**wezterm** (27 + 129 + Lua code):
- [ ] Check multiplexer integration
- [ ] Verify color scheme application
- [ ] Ensure keybindings work
- [ ] Test padding/font settings

**firefox** (179 lines + 489 impl.nix):
- [ ] Verify userChrome.css applies correctly
- [ ] Check extension IDs are still valid
- [ ] Ensure policies don't block features
- [ ] Verify theme matches system theme

---

## Home Manager Packages

**Overview**: 20 files managing packages across package managers

### modules/home/packages/default.nix (15 lines)

**Current State**: Aggregator for package managers

**Actions**:
- [ ] Verify all package manager imports are present
- [ ] Check for unused imports

**Dependencies**: 
- cargo/default.nix
- gh/default.nix
- go/default.nix
- kubectl/default.nix
- nixpkgs/default.nix
- node/default.nix
- python/default.nix
- vet/default.nix

**Risk Level**: 🟢 LOW

---

### Nixpkgs (1 file)

**modules/home/packages/nixpkgs/default.nix (160 lines)**

**Current State**: Main Nix packages list

**Actions**:
- [ ] Review each package for necessity
- [ ] Check for deprecated packages
- [ ] Verify no conflicting packages
- [ ] Ensure version pins are intentional

**Validation**:
```bash
nix eval '.#homeConfigurations.*.config.home.packages' | wc -w
```

**Risk Level**: 🟡 HIGH

---

### Language-Specific Package Managers (7 groups)

Each follows pattern: `<language>/default.nix` (entry) + `lib.nix` (helpers)

#### 1. **Node.js** (40 lines + npm/yarn helpers)

**Files**:
- default.nix (10 lines)
- lib.nix (40 lines)
- npm.nix (26 lines)
- yarn.nix (23 lines)

**Actions**:
- [ ] Verify Node version matches project needs
- [ ] Check npm/yarn versions are compatible
- [ ] Ensure global packages are necessary
- [ ] Verify no conflicts with corepack

**Validation**:
```bash
node --version
npm --version
yarn --version
```

**Risk Level**: 🟡 HIGH

---

#### 2. **Python** (37 lines + pipx/uvx helpers)

**Files**:
- default.nix (10 lines)
- lib.nix (37 lines)
- pipx.nix (16 lines)
- uvx.nix (20 lines)

**Actions**:
- [ ] Verify Python version (3.x)
- [ ] Check pip packages are using pipx
- [ ] Ensure no conflicting version managers
- [ ] Verify uvx is properly configured

**Validation**:
```bash
python3 --version
pip --version
pipx list
```

**Risk Level**: 🟡 HIGH

---

#### 3. **Cargo** (18 lines + 18 lib)

**Files**:
- default.nix (18 lines)
- lib.nix (18 lines)

**Actions**:
- [ ] Verify Rust toolchain is installed
- [ ] Check all Cargo packages are maintained
- [ ] Ensure no binary conflicts

**Validation**:
```bash
cargo --version
cargo install --list
```

**Risk Level**: 🟡 HIGH

---

#### 4. **Go** (33 lines + 23 lib)

**Files**:
- default.nix (33 lines)
- lib.nix (23 lines)

**Actions**:
- [ ] Verify Go version matches projects
- [ ] Check all Go packages are necessary
- [ ] Verify GOPATH is set correctly

**Validation**:
```bash
go version
go list ./...  # If in Go project
```

**Risk Level**: 🟡 HIGH

---

#### 5. **GitHub CLI** (19 lines + 25 lib)

**Files**:
- default.nix (19 lines)
- lib.nix (25 lines)

**Actions**:
- [ ] Verify gh is authenticated
- [ ] Check extensions are installed
- [ ] Ensure config is valid

**Validation**:
```bash
gh --version
gh auth status
```

**Risk Level**: 🟡 HIGH

---

#### 6. **Kubectl** (25 lines)

**Files**:
- default.nix (25 lines)

**Actions**:
- [ ] Verify kubectl version matches cluster
- [ ] Check plugins are installed
- [ ] Ensure kubeconfig is correct

**Validation**:
```bash
kubectl version --client
kubectl cluster-info
```

**Risk Level**: 🟡 HIGH

---

#### 7. **Vet** (18 lines + 11 lib)

**Files**:
- default.nix (18 lines)
- lib.nix (11 lines)

**Actions**:
- [ ] Verify vet is properly configured
- [ ] Check all checks are relevant
- [ ] Ensure no false positives

**Validation**:
```bash
vet --help
```

**Risk Level**: 🟢 LOW

---

## Shared Library

**Overview**: 29 files providing shared utilities used across entire config

### modules/shared/lib/default.nix (28 lines) - RECENTLY DOCUMENTED

**Current State**: Main export point with grouped comments

**Actions**:
- [x] ✅ Added comments grouping utilities
- [ ] Verify all exports are actually used
- [ ] Check dependency order (no circular deps)

**Validation**:
```bash
nix eval '.#utils' | head -20
```

**Dependencies**: All files in modules/shared/lib/*

**Risk Level**: 🔴 CRITICAL - All configs depend on this

---

### Platform Detection (135 lines)

**File**: modules/shared/lib/platform/default.nix

**Current State**: System type detection (Darwin/Linux, aarch64/x86_64)

**Actions**:
- [ ] Verify platform detection logic is correct
- [ ] Check all supported systems are listed
- [ ] Ensure no missing platform combinations

**Validation**:
```bash
nix eval '.#utils.platform.isDarwin'
nix eval '.#utils.platform.isLinux'
nix eval '.#utils.platform.isAarch64'
```

**Risk Level**: 🔴 CRITICAL - Many configs depend on this

---

### Paths Library (49 lines)

**File**: modules/shared/lib/paths/default.nix

**Current State**: Standard path helpers

**Actions**:
- [ ] Verify all XDG paths are correct
- [ ] Check cache/state paths exist
- [ ] Ensure permissions are sufficient

**Validation**:
```bash
nix eval '.#utils.paths.configDir'
```

**Risk Level**: 🟡 HIGH

---

### XDG Base Directories (88 lines)

**File**: modules/shared/lib/xdg/default.nix

**Current State**: XDG spec compliance

**Actions**:
- [ ] Verify all XDG variables are set
- [ ] Check for any hardcoded paths that should use XDG
- [ ] Ensure fallbacks are correct

**Validation**:
```bash
echo $XDG_CONFIG_HOME
echo $XDG_DATA_HOME
```

**Risk Level**: 🟡 HIGH

---

### Values/Configuration Schema (324 lines)

**File**: modules/shared/lib/values/default.nix

**Current State**: Type definitions and validation for values.nix

**Actions**:
- [ ] Verify all types match actual values.nix usage
- [ ] Check all validations are enforced
- [ ] Ensure schema is complete
- [ ] Add documentation for each type

**Validation**:
```bash
nix eval '.#utils.values'  # Should not error if values.nix is valid
```

**Dependencies**: values.nix (external)

**Risk Level**: 🔴 CRITICAL - Validates entire configuration

---

### Theme System (348 lines main + 600+ supporting)

**Core Files**:
- modules/shared/lib/theme/default.nix (348 lines)
- modules/shared/lib/theme/core/adapter-base.nix (92 lines)
- modules/shared/lib/theme/core/constants.nix (31 lines)
- modules/shared/lib/theme/core/types.nix (191 lines)
- modules/shared/lib/theme/core/utils.nix (399 lines)
- modules/shared/lib/theme/core/validators.nix (336 lines)
- modules/shared/lib/theme/core/palette-normalizer.nix (321 lines)

**Palette Files** (9 themes):
1. black-metal.nix (85 lines)
2. catppuccin.nix (146 lines)
3. everforest.nix (340 lines)
4. gruvbox.nix (136 lines)
5. kanagawa.nix (219 lines)
6. monokai.nix (104 lines)
7. nord.nix (68 lines)
8. retroism.nix (176 lines)
9. rose-pine.nix (110 lines)
10. solarized.nix (102 lines)
11. tokyonight.nix (169 lines)

**Adapter Files** (app-specific):
1. base16-schemes.nix (28 lines)
2. firefox.nix (816 lines)
3. gtk-retroism.nix (51 lines)
4. neovim.nix (86 lines)
5. theme-names.nix (156 lines)
6. wezterm.nix (129 lines)

**Actions** (theme system):

**Main theme/default.nix**:
- [ ] Verify all export functions are used
- [ ] Check palette loading is correct
- [ ] Ensure adapter selection works
- [ ] Validate all color transformations

**Core modules** (adapter-base, constants, types, utils, validators, palette-normalizer):
- [ ] Verify type system is complete
- [ ] Check validators catch all invalid inputs
- [ ] Ensure palette normalization handles all color formats
- [ ] Test utils work with all color spaces

**Palettes** (11 theme files):
- [ ] Verify each palette has all required colors
- [ ] Check color values are valid hex/RGB
- [ ] Ensure semantic colors are defined (background, foreground, etc.)
- [ ] Test each theme works with at least one app

**Adapters** (app-specific):
- [ ] Verify each adapter exports correct format for its app
- [ ] Check theme application works
- [ ] Test color override behavior

**Validation**:
```bash
# Test theme loading:
nix eval '.#utils.theme.getThemePalette "catppuccin" "macchiato"'

# Test adapter:
nix eval '.#utils.theme.getAppTheme "neovim" "catppuccin" "macchiato"'
```

**Risk Level**: 🔴 CRITICAL (affects all visual apps)

---

### Shell Utilities (30 + 40 = 70 lines)

**Files**:
- modules/shared/lib/shell/default.nix (30 lines)
- modules/shared/lib/shell/env.nix (40 lines)
- modules/shared/lib/shell/aliases.nix (54 lines)

**Actions**:
- [ ] Verify all aliases are documented
- [ ] Check env variables don't conflict
- [ ] Ensure shell completions work

**Validation**:
```bash
echo $PATH  # Should include all needed paths
which <alias>  # Should resolve for each alias
```

**Risk Level**: 🟡 HIGH

---

### Packages Management (7 + 81 = 88 lines)

**Files**:
- modules/shared/lib/packages/default.nix (7 lines)
- modules/shared/lib/packages/lib.nix (81 lines)

**Actions**:
- [ ] Verify package definitions are complete
- [ ] Check no circular dependencies
- [ ] Ensure overlay application is correct

**Risk Level**: 🟡 HIGH

---

### NixOS Modules (121 + 14 = 135 lines)

**Files**:
- modules/shared/lib/modules/theme.nix (121 lines)
- modules/shared/lib/modules/validation.nix (14 lines)

**Actions**:
- [ ] Verify theme module exports correct format
- [ ] Check validation catches errors
- [ ] Ensure NixOS module options are valid

**Risk Level**: 🟡 HIGH

---

## Overlays

**Overview**: 2 files for Nix package overrides

### overlays/default.nix (8 lines)

**Current State**: Aggregator for overlays

**Actions**:
- [ ] Verify both overlay imports are present
- [ ] Check no unused imports

**Dependencies**: 
- overlays/packages.nix

**Risk Level**: 🟢 LOW

---

### overlays/packages.nix (45 lines)

**Current State**: Package overrides and custom definitions

**Actions**:
- [ ] Review each override for necessity
- [ ] Check override versions match flake inputs
- [ ] Verify no conflicts with nixpkgs

**Validation**:
```bash
nix eval '.#overlays'
```

**Risk Level**: 🟡 HIGH - Modifies package behavior

---

## Validation & Testing

### Complete Validation Checklist

**Phase 1: Syntax & Build**
```bash
# Check all Nix files are syntactically valid
nix fmt --check modules/ overlays/ flake.nix

# Check flake is valid
nix flake check

# Build Darwin configuration
task nix:build:lv426

# Build NixOS configuration (if available)
task nix:build:arrakis
```

**Phase 2: Configuration Load**
```bash
# Evaluate main configs
nix eval '.#darwinConfigurations.lv426.config' 2>&1 | head -20
nix eval '.#nixosConfigurations.arrakis.config' 2>&1 | head -20

# Check values schema validation
nix eval '.#utils.values'
```

**Phase 3: Specific Module Tests**

For each major subsystem:
```bash
# Darwin
nix eval '.#darwinConfigurations.lv426.config.system.defaults'
nix eval '.#darwinConfigurations.lv426.config.services'
nix eval '.#darwinConfigurations.lv426.config.programs'

# NixOS
nix eval '.#nixosConfigurations.arrakis.config.boot'
nix eval '.#nixosConfigurations.arrakis.config.hardware'
nix eval '.#nixosConfigurations.arrakis.config.services'

# Home-manager
nix eval '.#homeConfigurations.*.config.programs'
```

**Phase 4: Runtime Tests** (post-deployment)
```bash
# Verify paths
[ -d $XDG_CONFIG_HOME ] && echo "XDG OK"

# Check shell
echo $SHELL
zsh --version
nu --version

# Check tools
which neovim && neovim --version
which git && git --version
which helix && hx --version
```

---

## Handoff Instructions

### For Another LLM Agent

**Context Needed**:
1. This document (NIX_FILES_COMPREHENSIVE_PLAN.md)
2. MODULE_STRUCTURE.md (architecture guide)
3. Current git commit (b9ce215d1 - recent standardization)

**High-Priority Files** (Review First):
1. flake.nix - System orchestrator
2. modules/shared/lib/values/default.nix - Config schema
3. modules/shared/lib/theme/default.nix - Theme system
4. modules/home/default.nix - Home-manager base

**Task Template**:
```
Given this task: [SPECIFIC TASK]

Reference files:
- NIX_FILES_COMPREHENSIVE_PLAN.md section: [SECTION]
- Affected files: [FILE LIST]

Actions required:
1. [Action 1]
2. [Action 2]
3. [Action 3]

Validation:
```
[validation commands]
```

Risk level: [GREEN/YELLOW/RED]
```

**Common Tasks**:

**Task: Update a package list**
- File: modules/home/packages/nixpkgs/default.nix (or language-specific)
- Validation: `nix eval '.#homeConfigurations.*.config.home.packages' 2>&1 | head -20`

**Task: Add new home-manager configuration**
- Files: 
  - Create: modules/home/configurations/<name>/default.nix
  - Update: modules/home/configurations/default.nix
- Validation: `nix eval '.#homeConfigurations.*.config.programs.<name>'`

**Task: Update theme**
- Files: 
  - modules/shared/lib/theme/palettes/<theme>.nix (or new theme)
  - modules/shared/lib/theme/adapters/*.nix (if app-specific)
- Validation: `nix eval '.#utils.theme.getThemePalette "theme" "variant"'`

**Task: Fix broken module**
- Reference: This plan + MODULE_STRUCTURE.md
- Follow validation steps for that category
- Commit with clear message referencing this plan

---

## Summary Statistics

| Category | Count | Total Lines | Complexity |
|----------|-------|------------|-----------|
| Flake Root & Config | 6 | 238 | 🟡 HIGH |
| Darwin System | 19 | 1,054 | 🟡 HIGH |
| NixOS System | 38 | 1,847 | 🟡 HIGH |
| Home Configurations | 76 | 5,600+ | 🟡 HIGH |
| Home Packages | 20 | 532 | 🟡 HIGH |
| Shared Library | 29 | 5,200+ | 🔴 CRITICAL |
| Overlays | 2 | 53 | 🟢 LOW |
| **TOTAL** | **182** | **14,500+** | - |

**Critical Files** (handle with care):
1. flake.nix
2. modules/shared/lib/values/default.nix
3. modules/shared/lib/theme/default.nix
4. modules/shared/lib/platform/default.nix
5. modules/home/default.nix
6. modules/darwin/default.nix
7. modules/nixos/default.nix

**Well-Documented** (low risk):
- All files in MODULE_STRUCTURE.md
- All files in AUDIT_SUMMARY.md (recently standardized)

**Needs Documentation** (add later):
- Individual Darwin configuration purposes
- Individual NixOS configuration purposes
- LLM agent prompt intentions
- Theme adapter logic for specific apps
