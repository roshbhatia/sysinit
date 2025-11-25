# Migration Guide: Adding NixOS Support

This guide explains the changes made to add NixOS support while maintaining backward compatibility with nix-darwin.

## What Changed

### 1. Multi-System Support

The flake now supports multiple system architectures:
- `aarch64-darwin` (Apple Silicon Macs)
- `x86_64-darwin` (Intel Macs)
- `aarch64-linux` (ARM Linux)
- `x86_64-linux` (x86_64 Linux)

### 2. New Directory Structure

```
.
├── hosts/                      # NEW: Host-specific configurations
│   ├── values.nix             # Common values for all personal machines
│   ├── lv426/                 # Personal MacBook
│   │   └── default.nix
│   ├── arrakis/               # Gaming Desktop (NixOS)
│   │   ├── default.nix
│   │   └── hardware-configuration.nix
│   └── urth/                  # Home Server (NixOS)
│       ├── default.nix
│       └── hardware-configuration.nix
├── modules/
│   ├── darwin/                # Existing: macOS-specific modules
│   ├── nixos/                 # NEW: NixOS-specific modules
│   │   ├── configurations/
│   │   │   ├── boot/
│   │   │   ├── networking/
│   │   │   ├── users/
│   │   │   ├── system/
│   │   │   └── services/
│   │   ├── packages/
│   │   └── home-manager.nix
│   ├── home/                  # Existing: Cross-platform user configs
│   └── lib/                   # Existing: Shared utilities
│       └── platform/          # UPDATED: Added homeDirectory helper
└── flake.nix                  # UPDATED: Multi-system support
```

### 3. Flake Changes

#### Old Behavior
```nix
darwinConfigurations = {
  ${hostname} = mkDarwinConfiguration { };
  default = mkDarwinConfiguration { };
};
```

#### New Behavior
```nix
# Automatically generates configurations for all hosts in hosts/values.nix
darwinConfigurations = {
  lv426 = ...;           # From hosts/values.nix
  ${hostname} = ...;     # Backward compatible with values.nix
  default = ...;         # Backward compatible
};

nixosConfigurations = {
  arrakis = ...;         # Gaming desktop
  urth = ...;            # Home server
};
```

### 4. Platform Detection Updates

The `utils.platform` module now includes a `homeDirectory` helper:

```nix
# Old way (hardcoded)
home.homeDirectory = "/Users/${username}";

# New way (cross-platform)
home.homeDirectory = utils.platform.homeDirectory username;
# Returns: "/Users/username" on macOS
#          "/home/username" on Linux
```

## Backward Compatibility

### For Work MacBook (or any external values.nix)

**No changes required!** The existing workflow continues to work:

```bash
darwin-rebuild switch --flake .
```

The flake still reads `values.nix` in the root directory and creates configurations for:
- `${hostname}` (from values.nix)
- `default`

### For Personal Machines

Personal machines (lv426, arrakis, urth) now use `hosts/values.nix` for configuration:

```bash
# macOS
darwin-rebuild switch --flake .#lv426

# NixOS
sudo nixos-rebuild switch --flake .#arrakis
sudo nixos-rebuild switch --flake .#urth
```

## Host-Specific Features

### lv426 (Personal MacBook)
- Full nix-darwin configuration
- Homebrew packages from hosts/values.nix
- All dotfiles via home-manager

### arrakis (Gaming Desktop)
- NixOS with GNOME desktop environment
- Steam and gaming packages
- GameMode for performance
- Tailscale networking
- Full dotfiles via home-manager

### urth (Home Server)
- NixOS headless server
- k3s Kubernetes cluster
- Docker support
- Tailscale networking
- Server monitoring tools
- Full dotfiles via home-manager

## NixOS Installation Steps

### For New NixOS Machines

1. **Install NixOS** using the standard installer

2. **Clone this repository**:
   ```bash
   git clone https://github.com/roshbhatia/sysinit.git
   cd sysinit
   ```

3. **Generate hardware configuration**:
   ```bash
   sudo nixos-generate-config --show-hardware-config > hosts/<hostname>/hardware-configuration.nix
   ```

4. **Review and update hardware config**:
   - Check filesystem mounts
   - Verify boot configuration
   - Update CPU microcode (Intel vs AMD)
   - Configure GPU drivers (NVIDIA, AMD, Intel)

5. **Build and switch**:
   ```bash
   sudo nixos-rebuild switch --flake .#<hostname>
   ```

### Common Post-Install Tasks

1. **Set user password**:
   ```bash
   sudo passwd rshnbhatia
   ```

2. **Connect to Tailscale**:
   ```bash
   sudo tailscale up
   ```

3. **For k3s (urth only)**:
   ```bash
   # Wait for k3s to start
   sudo systemctl status k3s

   # Copy kubeconfig for kubectl access
   mkdir -p ~/.kube
   sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config
   ```

4. **For gaming (arrakis only)**:
   ```bash
   # Steam will be available in applications menu
   # For EA/Origin games, use Heroic launcher (already installed)
   ```

## Values Schema

### Common Values (All Hosts)

Located in `hosts/values.nix`:

```nix
{
  common = {
    user.username = "rshnbhatia";
    git = {
      name = "Roshan Bhatia";
      email = "rshnbhatia@gmail.com";
      username = "roshbhatia";
    };
  };
}
```

### Host-Specific Values

```nix
hosts = {
  lv426 = {
    system = "aarch64-darwin";
    hostname = "lv426";
    darwin = {
      homebrew.additionalPackages = { ... };
    };
  };

  arrakis = {
    system = "x86_64-linux";
    hostname = "arrakis";
    # Gaming config in hosts/arrakis/default.nix
  };

  urth = {
    system = "x86_64-linux";
    hostname = "urth";
    # k3s config in hosts/urth/default.nix
  };
}
```

## Troubleshooting

### "attribute missing" errors

If you see errors about missing attributes, ensure you've added the host to `hosts/values.nix` and created the corresponding directory in `hosts/`.

### Home directory path issues

If home-manager complains about paths, verify that the `utils.platform.homeDirectory` function is being used instead of hardcoded paths.

### Hardware configuration issues

For NixOS, always generate a fresh hardware configuration on the target machine:

```bash
sudo nixos-generate-config --show-hardware-config
```

Compare with the template and update:
- Filesystem UUIDs
- Boot loader settings
- Kernel modules
- GPU drivers

### Steam/Gaming issues

If Steam doesn't launch:
1. Ensure 32-bit support is enabled (already configured)
2. Check GPU drivers are loaded: `lspci -k | grep -A 3 VGA`
3. Verify GameMode is available: `gamemoded --version`

### k3s issues

If k3s doesn't start:
1. Check firewall ports are open: `sudo nft list ruleset`
2. Verify kernel modules: `lsmod | grep br_netfilter`
3. Check k3s logs: `sudo journalctl -u k3s -f`

## Future Enhancements

Potential improvements to consider:

1. **Per-host theme overrides** - Different colorschemes per machine
2. **NixOS ISO builder** - Custom install media with pre-configured SSH
3. **Remote deployment** - Deploy to machines over SSH
4. **Secrets management** - Use sops-nix or agenix for sensitive configs
5. **Home-manager standalone** - Use home-manager without system config
