# PRD-01: Profile System

## Overview

Create a composable profile system that replaces monolithic host configurations with reusable, single-purpose profiles following Unix philosophy.

## Problem Statement

Current `flake/hosts.nix` uses large, monolithic `values` objects that mix concerns:
- Desktop configuration mixed with dev tools
- No clear separation between host and VM needs
- Hard to create variations (minimal, full, work, etc.)
- Duplication across similar configurations

## Proposed Solution

Introduce a `profiles/` directory with composable, single-purpose profiles that can be mixed and matched to create different system configurations.

## Scope

### In Scope
- Create `profiles/` directory structure
- Implement base, desktop, and dev profiles
- Create host-minimal profile (for macOS)
- Create dev-full and dev-minimal profiles (for VMs)
- Update `flake/hosts.nix` to use profiles
- Update `flake/outputs.nix` to handle profiles

### Out of Scope
- Refactoring individual modules (happens in PRD-02)
- Creating Lima VMs (happens in PRD-03)
- Changing theme system
- Modifying existing arrakis configuration

## Technical Design

### Directory Structure

```
profiles/
├── base.nix           # Core: Nix settings, essential utils
├── desktop.nix        # Desktop: GUI apps, window management, theming
├── host-minimal.nix   # Minimal macOS host composition
├── dev-full.nix       # Complete dev environment
├── dev-minimal.nix    # Basic dev tools only
└── default.nix        # Export all profiles
```

### Profile Definitions

**profiles/base.nix**
```nix
{ pkgs, lib, ... }: {
  # Nix daemon settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # ... other core settings
  };
  
  # Available everywhere
  home.packages = with pkgs; [ curl wget ];
}
```

**profiles/desktop.nix**
```nix
{ ... }: {
  imports = [
    ../modules/darwin/configurations/aerospace.nix
    ../modules/darwin/configurations/borders.nix
    ../modules/darwin/configurations/sketchybar.nix
    ../modules/darwin/configurations/stylix.nix
    ../modules/darwin/configurations/desktop.nix
  ];
  
  home-manager.users = {
    imports = [
      ../modules/home/configurations/firefox
    ];
  };
}
```

**profiles/dev-full.nix**
```nix
{ pkgs, ... }: {
  imports = [
    ./base.nix
    ../modules/home/configurations/neovim
    ../modules/home/configurations/helix
    ../modules/home/configurations/git
    ../modules/home/configurations/zellij
    ../modules/home/configurations/fzf
    ../modules/home/configurations/direnv
    ../modules/home/configurations/zoxide
    ../modules/home/configurations/bat
    ../modules/home/configurations/eza
    ../modules/home/configurations/fd
    ../modules/home/configurations/ast-grep
  ];
  
  home.packages = with pkgs; [
    # Dev toolchains
    nodejs python3 rustc cargo go
    # CLI tools
    ripgrep fd bat eza delta
  ];
}
```

**profiles/host-minimal.nix**
```nix
{ pkgs, ... }: {
  imports = [
    ./base.nix
    ./desktop.nix
  ];
  
  # Lima runtime for VMs
  environment.systemPackages = [ pkgs.lima ];
  
  home-manager.users.rshnbhatia = {
    imports = [
      # Terminal only - will connect to VMs
      ../modules/home/configurations/ghostty  # PRD-04
      # Minimal shell for host operations
      ../modules/home/configurations/zsh
      # Essential CLI tools
      ../modules/home/configurations/git
    ];
    
    home.packages = with pkgs; [
      # File navigation
      ripgrep fd bat eza
      # System tools
      htop
    ];
  };
}
```

**profiles/default.nix**
```nix
{ nixpkgs, ... }: {
  base = import ./base.nix;
  desktop = import ./desktop.nix;
  host-minimal = import ./host-minimal.nix;
  dev-full = import ./dev-full.nix;
  dev-minimal = import ./dev-minimal.nix;
}
```

### Updated flake/hosts.nix

```nix
common:

{
  # macOS host - use minimal profile
  lv426 = {
    system = "aarch64-darwin";
    platform = "darwin";
    inherit (common) username;
    
    # Reference profile instead of inline values
    profile = "host-minimal";
    
    # Host-specific overrides
    values = common.values // {
      theme = {
        colorscheme = "everforest";
        variant = "dark-soft";
      };
      darwin.homebrew.additionalPackages.casks = [
        "discord"
        "steam"
      ];
    };
  };
  
  # Existing arrakis unchanged
  arrakis = {
    system = "x86_64-linux";
    platform = "linux";
    inherit (common) username;
    values = common.values // {
      # ... existing config
    };
  };
  
  # Lima dev VM (PRD-03)
  lima-dev = {
    system = "aarch64-linux";
    platform = "linux";
    username = "dev";
    
    profile = "dev-full";
    
    values = common.values // {
      theme.colorscheme = "everforest";
    };
  };
  
  # Lima minimal VM (PRD-03)
  lima-minimal = {
    system = "aarch64-linux";
    platform = "linux";
    username = "dev";
    
    profile = "dev-minimal";
    
    values = common.values;
  };
}
```

### Updated flake/builders.nix

Add profile resolution logic:

```nix
# flake/builders.nix additions
let
  profiles = import ../profiles { inherit nixpkgs; };
  
  resolveProfile = hostConfig:
    if hostConfig ? profile
    then profiles.${hostConfig.profile}
    else null;  # Fallback to old values-based system
in
{
  # ... existing buildConfiguration ...
  
  # Use in module list:
  modules = [
    # ... existing modules ...
  ] ++ lib.optional (resolveProfile hostConfig != null) (resolveProfile hostConfig);
}
```

## Acceptance Criteria

All criteria must pass for PRD completion.

**Directory Structure**
- `profiles/` directory exists with all 5 profile files
- Each profile is a valid Nix module that can be imported
- `profiles/default.nix` exports all profiles as an attribute set

**Flake Integration**
- `flake/hosts.nix` references profiles via `profile = "name"` attribute
- lv426 configuration uses `host-minimal` profile
- lima-dev configuration exists with `dev-full` profile
- lima-minimal configuration exists with `dev-minimal` profile

**Build Validation**
- `task nix:validate` passes without errors
- `nix flake check` succeeds
- `task nix:build:lv426` succeeds
- `task nix:build:arrakis` succeeds (unchanged from before)
- No new build warnings or errors introduced

**System Functionality**
- `task nix:refresh:lv426` applies successfully
- System boots and desktop environment loads
- Firefox launches with correct everforest theme
- Discord launches successfully
- Aerospace window management keybindings work
- Sketchybar displays with correct information
- Terminal (WezTerm) opens and accepts commands
- Git commands execute successfully
- All Homebrew casks accessible

**Regression Prevention**
- No packages removed that were present before
- All previous functionality preserved
- No configuration options lost
- arrakis configuration completely unchanged

## Testing Procedure

### Pre-Flight Check
```bash
# Save current generation
darwin-rebuild --list-generations | head -5

# Create backup tag
git tag pre-profile-system
```

### Build Test
```bash
# Validate flake
task nix:validate

# Test build without applying
task nix:build:lv426

# Check what will change
darwin-rebuild build --flake .#lv426
nix store diff-closures /run/current-system ./result
```

### Apply Test
```bash
# Apply configuration
task nix:refresh:lv426

# Verify system state
echo "Testing desktop apps..."
open -a Firefox  # Should launch
open -a Discord  # Should launch

echo "Testing window management..."
# Press Cmd+Shift+Space (Aerospace)
# Verify windows move

echo "Testing terminal..."
# Open terminal
git status  # Should work

echo "Testing theme..."
# Verify colors match everforest dark-soft
```

### Rollback Test
```bash
# If anything fails:
darwin-rebuild --rollback

# OR
git reset --hard pre-profile-system
task nix:refresh:lv426
```

## Implementation Steps

1. **Create profile structure**
   ```bash
   mkdir -p profiles
   touch profiles/{base,desktop,host-minimal,dev-full,dev-minimal,default}.nix
   ```

2. **Implement base.nix**
   - Copy core Nix settings from existing config
   - Add essential packages

3. **Implement desktop.nix**
   - Import all darwin/configurations/desktop modules
   - Import home/configurations/firefox

4. **Implement dev-full.nix**
   - Import all dev-related home configurations
   - Add dev packages

5. **Implement dev-minimal.nix**
   - Import only essential dev tools
   - Minimal package set

6. **Implement host-minimal.nix**
   - Compose base + desktop
   - Add minimal home-manager config
   - Add Lima package

7. **Create default.nix**
   - Export all profiles as attrset

8. **Update flake/hosts.nix**
   - Add `profile` field to lv426
   - Add lima-dev and lima-minimal (stub for now)

9. **Update flake/builders.nix**
   - Add profile resolution logic
   - Apply profiles in module list

10. **Test**
    - Run acceptance criteria tests
    - Verify no regressions

11. **Commit**
    ```bash
    git add profiles/ flake/
    git commit -m "feat: introduce composable profile system

    - Add profiles/ directory with 5 base profiles
    - Update hosts.nix to reference profiles
    - Update builders.nix to resolve profiles
    - lv426 now uses host-minimal profile
    - Add stub lima-dev and lima-minimal configs
    
    All acceptance criteria met. No regressions detected."
    ```

## Rollback Plan

### If Build Fails
```bash
# Fix syntax errors and try again
# No system changes yet, safe to iterate
```

### If Apply Fails
```bash
# Rollback to previous generation
darwin-rebuild --rollback

# Or rollback in nix-darwin
sudo darwin-rebuild switch --rollback
```

### If System Works But Has Issues
```bash
# Revert commits
git reset --hard pre-profile-system

# Rebuild from clean state
task nix:refresh:lv426
```

### Nuclear Option
```bash
# Restore from Time Machine if completely broken
# (Make TM backup before starting!)
```

## Dependencies

**Blocks**: PRD-02, PRD-03, PRD-06
**Blocked By**: None

This is the foundation PRD. All other PRDs depend on the profile system being in place.

## Future Enhancements

- Work profile for work-specific configs
- Gaming profile for gaming-related packages
- Server profile for headless systems
- Per-project profiles (defined in project repos)

## Notes

- Profile system is purely additive - doesn't break existing configs
- Old values-based system still works as fallback
- Can incrementally migrate hosts to use profiles
- arrakis intentionally left on old system (not migrating)
