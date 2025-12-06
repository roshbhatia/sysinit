# Migration Guide: Multi-System Refactoring

This guide explains how to use the refactored flake structure.

## For Personal Machine (macOS)

**Before**: Your setup remains unchanged. Existing commands work:

```bash
# Your laptop continues to work exactly as before
task nix:build      # Still works
task nix:refresh    # Still works
task nix:build:work # Now builds work-repo's sysinit independently
```

**No action needed** - your current workflow is fully backward compatible.

## For Work Machine Setup

**New approach** (optional):
Instead of having a separate work sysinit repo that recursively searches for this repo, the work machine can consume this as a flake input:

```nix
# work-flake/flake.nix
inputs = {
  personal-sysinit = {
    url = "github:roshbhatia/sysinit";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};

outputs = { personal-sysinit, ... }:
  {
    darwinConfigurations.work-laptop = personal-sysinit.lib.mkDarwinConfiguration {
      hostname = "work-laptop";
      values = import ./values.nix;  # Work-specific configuration
    };
  };
```

**Benefits**:
- No recursive repo searching
- Clear dependency declaration
- Work machine can be built independently
- Different nixpkgs version if needed
- Cleaner separation of concerns

## For Arrakis (NixOS Desktop)

**When arrakis hardware is ready**:

1. Get hardware configuration from the machine:
```bash
sudo nixos-generate-config --root /tmp/arrakis-config
cp /tmp/arrakis-config/etc/nixos/hardware-configuration.nix \
   sysinit/modules/nixos/arrakis-hardware.nix
```

2. Update flake.nix to enable NixOS:
```nix
nixosConfigurations = mkNixosConfigurations;
```

3. Create arrakis-specific modules as needed:
```
modules/nixos/configurations/
├── gaming.nix         # Steam, Proton, driver setup
├── audio.nix         # PulseAudio/PipeWire
├── display.nix       # X11/Wayland
└── hardware.nix      # Hardware-specific
```

4. Build and test:
```bash
# From gaming-desktop machine
nix build ".#nixosConfigurations.gaming-desktop.config.system.build.toplevel"
sudo nixos-rebuild switch --flake ".#gaming-desktop"
```

## Configuration Locations

**Centralized host configuration** (replaces values.nix):
```nix
# In flake.nix
hostConfigs = {
  lv426 = {
    system = "aarch64-darwin";
    platform = "darwin";
    username = "rshnbhatia";
    values = { ... };
  };
  arrakis = {
    system = "aarch64-linux";
    platform = "linux";
    username = "rshnbhatia";
    values = { ... };
  };
};
```

To add a new host, add a new entry to `hostConfigs` in flake.nix.

## Library Usage

The flake now exports builder functions for external consumption:

```nix
personal-sysinit.lib = {
  mkDarwinConfiguration = /* ... */;
  mkNixosConfiguration = /* ... */;
  processValues = /* ... */;
  mkPkgs = /* ... */;
  mkUtils = /* ... */;
  mkOverlays = /* ... */;
  hostConfigs = { lv426, gaming-desktop };
  systems = { laptop, desktop, work };
};
```

## Troubleshooting

**macOS build fails after refactoring**:
- This shouldn't happen - configurations are backward compatible
- Try: `nix flake update && task nix:refresh`
- Check that your hostname matches `hostConfigs` entry (default: "lv426")

**NixOS config won't evaluate**:
- The framework is in place but needs hardware-configuration.nix
- Until then, NixOS is commented out in flake.nix
- Provide hardware-configuration and uncomment the line

**Work machine won't build**:
- Ensure personal-sysinit flake input is configured
- Verify your work-specific values.nix has all required fields
- Check that values schema matches this repo's schema

## Future Improvements

This refactoring enables:
1. Zero-downtime multi-system support
2. Independent updates for each machine
3. Shared configuration for multi-account setups (personal/work git)
4. Template-based host addition
5. Easy flake input consumption by other projects
