# Discrete Host Configuration Template

This template creates a minimal flake that consumes `roshbhatia/sysinit` as an input.

## Setup

1. Update `hosts/default.nix`:
   - Change `yourusername` in the `defaults` section
   - Update git config (name, email, username)
   - Customize theme and other values
   - Update hostname in the host configuration (e.g., `yourhostname`)

2. Create host-specific modules:
   - `modules/darwin/default.nix` for macOS-specific config
   - `modules/nixos/default.nix` for NixOS-specific config

3. Add host-specific overlays in `overlays/default.nix`

4. Build and apply:
   ```bash
   nh darwin switch --update .  # Apply configuration
   ```

## Lima VM (Optional)

To create a NixOS Lima VM for this host:

1. Update `lima.yaml`:
   - Update any mount points or resource allocations as needed

2. Update `hosts/default.nix`:
   - Uncomment the NixOS host configuration
   - Set the hostname for your VM

3. Start the Lima VM:
   ```bash
   limactl start --name=default lima.yaml
   ```

4. Apply NixOS configuration using nh (specify hostname explicitly):
   ```bash
   lima -- nix run nixpkgs#nh os switch '.#your-nixos-hostname'
   ```

