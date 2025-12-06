# Multi-System Refactoring Plan

This document outlines the incremental refactoring to support multiple systems (macOS + NixOS) without breaking changes.

## PR #1: Inline values.nix and add multi-system skeleton ✅

**Status**: Ready for review

**Changes**:
- Deleted standalone `values.nix` 
- Inlined user/host configuration directly into `flake.nix`
- Added `hostConfigs` attribute with platform-specific settings (darwin/linux)
- Added `systems` mapping for quick reference
- Refactored flake outputs to support multiple systems:
  - `mkDarwinConfiguration` - Build darwin configs
  - `mkNixosConfiguration` - Build NixOS configs (disabled until modules/nixos created)
  - `processValues` - Validate values against schema
  - `mkPkgs`, `mkUtils`, `mkOverlays` - Extracted as reusable functions
- Exported library functions for work machine consumption
- Maintained backward compatibility with existing macOS workflow

**Why this works**:
- macOS laptop (`lv426`) continues to work exactly as before
- Values are now centralized and type-validated
- Configuration is declarative and extensible
- No breaking changes to existing workflows
- Work machine can now consume this as a library

**Testing**:
```bash
nix eval '.#lib' --impure  # Verify lib exports
nix eval '.#darwinConfigurations.lv426' --impure  # Verify darwin config exists
```

## PR #2: Add NixOS module structure ✅

**Status**: Ready for review

**Changes**:
- Created `modules/nixos/` directory structure mirroring `modules/darwin/`
- Added `modules/nixos/default.nix` with common NixOS settings
- Added `modules/nixos/configurations/default.nix` for import organization
- Added `modules/nixos/configurations/hardware.nix` placeholder for hardware-specific config
- Updated flake to create `mkNixosConfigurations` (disabled pending hardware-configuration.nix)
- Library functions `mkNixosConfiguration` now available for external use

**Structure**:
```
modules/nixos/
├── configurations/
│   ├── default.nix         # Configuration imports
│   ├── hardware.nix        # Hardware-specific (boot, filesystems)
│   └── [more configs]      # display, audio, gaming, etc.
└── default.nix             # NixOS module entry point
```

**Why this works**:
- Framework is in place for NixOS gaming-desktop configuration
- No changes to macOS workflow
- Can be incrementally extended with gaming-specific modules
- Hardware configuration can be added when gaming-desktop is ready

**Next step**:
- When gaming-desktop exists, provide its `hardware-configuration.nix`
- Uncomment `nixosConfigurations = mkNixosConfigurations;` in flake.nix
- Add gaming/audio/display modules

## PR #3: Add arrakis (NixOS desktop) configuration

Add full NixOS desktop configuration for arrakis:
- GPU drivers (nvidia/amd)
- Audio system setup
- Gaming-specific packages (Steam, Proton, etc.)
- Display server configuration
- Performance optimizations

No changes to existing macOS setup.

## PR #4: Export library functions for work machine

Update work machine flake to use:
```nix
inputs.personal-sysinit.lib.mkDarwinConfiguration {
  hostname = "work-laptop";
  values = import ./values.nix;
}
```

This enables work machine to:
- Pull this repo as a flake dependency
- Use common home modules
- Have independent values/configuration
- Update independently without forcing this repo updates

## PR #5: Update tasks for multi-system builds

Update `Taskfile.yml`:
```bash
task nix:build:gaming-desktop  # Build gaming desktop config
task nix:refresh:gaming-desktop  # Apply gaming desktop config
task nix:build:all  # Build all available configs
```

Remove old work-specific tasks that searched for separate repos.

## Current Architecture

Before:
```
sysinit (this repo)
  └── values.nix (external file)
  └── modules/darwin/

work-repo (separate flake)
  └── pulls sysinit somehow?
  └── values.nix
```

After:
```
sysinit (this repo)
  ├── flake.nix (inlined values for all hosts)
  ├── modules/darwin/ (macOS configs)
  ├── modules/nixos/  (NixOS configs)
  ├── modules/home/   (shared for all platforms)
  └── lib exports (for external consumption)

work-repo (separate flake)
  ├── uses personal-sysinit as flake input
  ├── values.nix (work-specific overrides)
  └── config uses lib.mkDarwinConfiguration
```

## Benefits

1. **No single-machine setup requirement** - can build any config independently
2. **Centralized configuration** - all hosts in one place
3. **Reusable library** - work machine or others can consume cleanly
4. **Type safety** - schema validation at build time
5. **Extensible** - adding new systems is straightforward
6. **No breaking changes** - existing macOS workflow unchanged
