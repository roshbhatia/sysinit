# Discrete Host Configuration

This template creates a minimal flake that consumes `roshbhatia/sysinit` as an input for host-specific configurations.

## Quick Start

### Build and Apply Configuration

`nh` reaches PATH only after the first switch, so run it through `nix run` once.

macOS:

```bash
nix run nixpkgs#nh -- darwin switch .
nh darwin switch .
```

NixOS:

```bash
nix run nixpkgs#nh -- os switch .
nh os switch .
```

### 1. Update Host Configuration

Edit `hosts/default.nix`:
- Change `username` in the `defaults` section
- Update git config (name, email, username)
- Customize theme and other values
- Update hostname in host configurations

### 2. Create Host-Specific Modules

- `modules/darwin/default.nix` for macOS-specific config
- `modules/nixos/default.nix` for NixOS-specific config

### 3. Add Host Overlays

Edit `overlays/default.nix` for any package customizations
