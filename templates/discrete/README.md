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
   nh darwin build   # Test build
   nh darwin switch  # Apply configuration
   ```

## Lima VM (Optional)

To create a NixOS Lima VM for this host:

1. Update `lima.yaml`:
   - Change the hostname in the provision script (line 42)
   - Update any mount points or resource allocations as needed

2. Update `hosts/default.nix`:
   - Uncomment the NixOS host configuration
   - Set the hostname to match the one in `lima.yaml`

3. Start the Lima VM:
   ```bash
   limactl start --name=default lima.yaml
   ```

4. Set hostname (NixOS doesn't allow runtime changes, so this must be done before first rebuild):
   ```bash
   lima -- sudo hostname your-nixos-hostname
   ```

5. Apply NixOS configuration using nh:
   ```bash
   lima -- nix run nixpkgs#nh -- os switch .
   ```

   Note: If the hostname in step 4 matches your NixOS configuration name in `hosts/default.nix`, nh will auto-detect it. Otherwise, specify explicitly:
   ```bash
   lima -- nix run nixpkgs#nh -- os switch '.#your-nixos-hostname'
   ```
