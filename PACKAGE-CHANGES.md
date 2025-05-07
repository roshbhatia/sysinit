# Package Management Improvements

## Overview

We've consolidated package definitions to avoid duplication between `system.nix` and `core/packages.nix`.

## Key Files Modified

- ✅ Created `modules/lib/packages.nix` to define system-level packages (previously in system.nix)
- ✅ Updated `modules/darwin/home/core/packages.nix` to focus on home-manager packages
- ✅ Updated `modules/darwin/system.nix` to import and use the centralized package definitions

## Benefits

1. **Reduced Duplication**: Package definitions are now defined in a single place
2. **Better Organization**: Clear separation between system packages and home-manager packages
3. **Easier Maintenance**: Adding or modifying packages is now simpler

## How it Works

### Package Definitions

The packages are now organized as follows:

1. **System Packages** (`modules/lib/packages.nix`):
   - Installed at the system level when Homebrew is disabled
   - Used by `system.nix` for system-wide installations

2. **Home Packages** (`modules/darwin/home/core/packages.nix`):
   - Installed through home-manager
   - User can add additional packages via `userConfig.packages.additional`

### Import Structure

```
system.nix
└── imports system packages from modules/lib/packages.nix

core/packages.nix
└── defines home-manager packages
```

## Configuration Example

If you want to add additional packages to your configuration, you can use the `userConfig` parameter:

```nix
{
  packages.additional = with pkgs; [
    your-package
    another-package
  ];
}
```

These packages will be automatically added to your home-manager configuration.
