# Sysinit Refactoring: Multi-System Support

## Overview

This refactoring enables the sysinit repo to support multiple systems (macOS + NixOS) cleanly without forcing sequential machine setup or breaking existing workflows.

**Status**: Two PRs ready, framework complete, no breaking changes

## What Changed

### Core Changes
1. **Inlined `values.nix` into `flake.nix`**
   - Centralized host/user configuration
   - Type-validated at build time
   - Easier to manage multiple systems

2. **Added multi-system infrastructure**
   - `hostConfigs` - Define all managed systems in one place
   - Platform-specific settings (darwin vs linux)
   - Reusable builder functions exported as library

3. **Created NixOS module skeleton**
   - `modules/nixos/` mirrors `modules/darwin/` structure
   - Ready for arrakis (NixOS desktop) configuration
   - Shared `modules/home/` works for both platforms

## Architecture

### Before
```
sysinit/
├── values.nix                 ← Single file, tight coupling
├── flake.nix                  ← Darwin only
├── modules/darwin/
├── modules/home/
└── work-machine-specific code in task runner
```

### After
```
sysinit/
├── flake.nix                  ← Multi-system, values inlined
├── modules/
│   ├── darwin/               ← macOS configs (unchanged)
│   ├── nixos/                ← NixOS configs (new)
│   ├── home/                 ← Shared home-manager
│   └── lib/                  ← Utilities
└── docs/
    ├── PR_REFACTORING.md
    ├── MIGRATION_GUIDE.md
    └── REFACTORING_SUMMARY.md (this file)
```

## Host Configuration

All hosts defined in one place in `flake.nix`:

```nix
hostConfigs = {
  lv426 = {
    system = "aarch64-darwin";
    platform = "darwin";
    username = "rshnbhatia";
    values = {
      user = { ... };
      git = { ... };
      darwin = { ... };
    };
  };
  arrakis = {
    system = "aarch64-linux";
    platform = "linux";
    username = "rshnbhatia";
    values = {
      user = { ... };
      git = { ... };
    };
  };
};
```

**Adding a new machine**: Just add an entry to `hostConfigs`.

## Exported Library Functions

External flakes can now consume sysinit as a library:

```nix
inputs.personal-sysinit = {
  url = "github:roshbhatia/sysinit";
  inputs.nixpkgs.follows = "nixpkgs";
};

# Available for use:
personal-sysinit.lib.mkDarwinConfiguration
personal-sysinit.lib.mkNixosConfiguration
personal-sysinit.lib.processValues
personal-sysinit.lib.mkPkgs
personal-sysinit.lib.mkUtils
personal-sysinit.lib.mkOverlays
personal-sysinit.lib.hostConfigs
personal-sysinit.lib.systems
```

This enables the work machine to cleanly import common configurations without directory searches.

## Current State by PR

### ✅ PR #1: Inline values.nix + Multi-System Foundation
**Commits**: Staged, ready to push
**Changes**:
- Deleted `values.nix`
- Restructured `flake.nix` for multi-system support
- Inlined host configurations with centralized schema validation
- Extracted reusable builder functions
- Exported library for external consumption
- All existing macOS workflows unchanged

**Testing**: `nix eval '.#lib' --impure` shows all exports

### ✅ PR #2: NixOS Module Structure
**Commits**: Staged, ready to push
**Changes**:
- Created `modules/nixos/` with proper structure
- Added `modules/nixos/default.nix` - Entry point with common settings
- Added `modules/nixos/configurations/default.nix` - Import organization
- Added `modules/nixos/configurations/hardware.nix` - Hardware config placeholder
- Library function `mkNixosConfiguration` ready to use

**Status**: Framework complete, evaluation disabled until hardware-configuration.nix provided

### ⏳ PR #3: Arrakis (NixOS Desktop) Configuration (Next)
**Will contain**:
- GPU driver configuration (nvidia/amd)
- Audio subsystem (PipeWire/ALSA)
- Display server setup (X11/Wayland)
- Gaming packages (Steam, Proton, wine)
- Performance optimizations

### ⏳ PR #4: Work Machine Library Usage (Optional)
**Description**: Update work-repo to use this as a flake input instead of searching

### ⏳ PR #5: Multi-System Task Support (Next)
**Will add tasks**:
```bash
task nix:build:arrakis    # Build NixOS config
task nix:refresh:arrakis  # Apply NixOS config
task nix:build:all               # Build all configs
task nix:status                  # Show all system statuses
```

## Backward Compatibility

✅ **Your macOS laptop workflow is 100% unchanged**:
- `task nix:build` works exactly as before
- `task nix:refresh` works exactly as before
- Hostname remains "lv426"
- Git config remains the same
- All home-manager configuration unchanged
- All darwin configuration unchanged

Only difference: You're using a cleaner, more maintainable config structure.

## Benefits

1. **No forced sequential setup** - Can build any system independently
2. **Single source of truth** - All host configs in flake.nix
3. **Type safety** - Values validated against schema at build time
4. **Reusable** - External projects can consume as library
5. **Extensible** - Easy to add new systems/machines
6. **Clean separation** - Platform-specific code properly organized
7. **Incremental** - Each machine can be enabled independently
8. **No surprises** - Work machine doesn't need to find this repo

## Quick Reference

### Build your macOS config
```bash
nix build ".#darwinConfigurations.lv426.system"
```

### Build all available configs
```bash
nix eval '.#darwinConfigurations' --impure   # macOS
# nix eval '.#nixosConfigurations' --impure  # NixOS (not yet)
```

### Check what's exported
```bash
nix eval '.#lib' --impure
```

### Add a new machine
1. Add entry to `hostConfigs` in `flake.nix`
2. If NixOS, provide `hardware-configuration.nix`
3. Add platform-specific modules as needed
4. Create corresponding task if needed

## Testing Status

- ✅ Flake structure validates (`nix flake show`)
- ✅ Library exports present (`nix eval '.#lib'`)
- ✅ Darwin configuration recognized
- ✅ No breaking changes to existing workflows
- ✅ Schema validation works (inlined values)

## Next Steps

1. **Review & merge** PR #1 + PR #2 (framework is solid)
2. **When arrakis ready**: Provide hardware-configuration
3. **Then**: Create PR #3 with gaming-specific modules
4. **Optional**: PR #4 to update work-machine setup
5. **Final**: PR #5 to add multi-system tasks

## Questions?

See:
- `PR_REFACTORING.md` - Detailed PR descriptions
- `MIGRATION_GUIDE.md` - How to use the new structure
- `AGENTS.md` - Development guidelines (updated)

---

**Current staged changes** (ready to commit):
- flake.nix (259 lines added/modified)
- modules/nixos/default.nix (13 lines)
- modules/nixos/configurations/default.nix (13 lines)
- modules/nixos/configurations/hardware.nix (14 lines)
- PR_REFACTORING.md (141 lines)
- values.nix (deleted, 32 lines)
