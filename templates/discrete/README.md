# Discrete Host Configuration

This template creates a minimal flake that consumes `roshbhatia/sysinit` as an input for host-specific configurations.

## Quick Start

### Build and Apply Configuration

```bash
# First run needs the nix run, then can be omitted
nix run nixpkgs#nh -- os switch .
nh os switch .
```

### Lima NixOS VM (Optional)

```bash
# Create persistent nix store directory
mkdir -p ~/.local/share/lima/<hostname>-nix

# Start Lima VM
limactl create --name=<hostname> lima.yaml
limactl start <hostname>

# Shell into the VM
limactl shell <hostname>

# From INSIDE the VM, apply configuration
# First run needs the nix run, then can be omitted
nix run nixpkgs#nh -- os switch '.#nixosConfigurations.<hostname>'
nh os switch '.#nixosConfigurations.<hostname>'
```

CRITICAL: Do NOT run `nh os switch` from macOS to configure the Lima VM. You must run it from INSIDE the VM.

## Setup

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

Create `overlays/default.nix` for any package customizations

### 4. Lima VM Configuration (Optional)

Edit `lima.yaml` to customize resource allocation and mounts

## Environment Variables

Host-specific environment variables can be set in `hosts/default.nix`:

```nix
values = {
  inherit (common) theme git;
  user.username = common.username;
  hostname = "your-hostname";
  environment = {
    # These will be available in zsh/fish and all programs
    CUSTOM_VAR = "value";
  };
};
```

## Validation

```bash
nix flake check               # Validate flake configuration
```

## Updating Dependencies

```bash
nix flake update              # Update all inputs
nix flake lock --update-input sysinit  # Update just sysinit
```
