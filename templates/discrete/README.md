# Discrete Host Configuration Template

This template creates a minimal flake that consumes `roshbhatia/sysinit` as an input.

## Setup

1. Update `flake.nix`:
   - Change `yourusername`, `yourhostname`, and git config
   - Customize theme and other values
   - Add/remove host configurations as needed

2. Create host-specific modules:
   - `modules/darwin/default.nix` for macOS-specific config
   - `modules/nixos/default.nix` for NixOS-specific config

3. Add host-specific overlays in `overlays/default.nix`

4. Build and apply:
   ```bash
   nh darwin build   # Test build
   nh darwin switch  # Apply configuration
   ```

## Directory Structure

```
.
├── flake.nix              # Main flake definition
├── modules/
│   ├── darwin/            # macOS-specific modules
│   │   └── default.nix
│   └── nixos/             # NixOS-specific modules
│       └── default.nix
└── overlays/              # Host-specific package overlays
    └── default.nix
```
