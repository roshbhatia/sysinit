# SysInit Examples

This directory contains example configurations for SysInit.

## Files

- `work-config.nix`: An example configuration file for a work setup
- `work-flake.nix`: An example flake file for a separate repository that imports SysInit

## How to Use the Work Config

### Option 1: Using the config file with existing SysInit

```bash
# Clone SysInit
git clone https://github.com/roshbhatia/sysinit.git
cd sysinit

# Use the work config
darwin-rebuild switch --flake .#lib.mkConfigWithFile ./examples/work-config.nix
```

### Option 2: Creating a separate repository

1. Create a new repository for your work configuration
2. Copy the `work-flake.nix` to your new repository as `flake.nix`
3. Copy the `work-config.nix` to your new repository
4. Update paths and configurations as needed
5. Build your configuration:

```bash
# In your work configuration repository
darwin-rebuild switch --flake .#default
```

## Directory Structure

```
examples/
├── README.md
├── wall/
│   └── company-logo.jpg
├── work-config.nix
├── work-configs/
│   ├── ssh-config
│   └── vpn-config
└── work-flake.nix
```