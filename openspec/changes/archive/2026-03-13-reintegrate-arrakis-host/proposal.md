## Why

The `arrakis` NixOS host (physical x86_64-linux desktop) was removed during a major refactor that prioritized Lima-based development. Reintegrating it as a first-class citizen ensures the system remains portable across both virtual and physical Linux hardware, while adopting the project's new architectural patterns (e.g., `values`-driven configuration and modularized NixOS settings).

## What Changes

- **Tiered Configuration Structure**: Organize NixOS settings into three distinct layers:
  - **Common**: Base settings shared by all NixOS systems (User, SSH, Nix settings, Shells).
  - **Lima-Specific**: Virtualization-only settings (Mount points, QEMU guest agent, serial console auto-login).
  - **Desktop-Specific**: GUI and hardware-oriented settings (Mangowc compositor, Waybar, Greetd, PipeWire, Gaming).
- **Restore Physical NixOS Support**: Re-introduce the `arrakis` host (`x86_64-linux`), decoupled from Lima assumptions.
- **Dynamic Home Directories**: Ensure `home-manager` correctly maps directories for both physical (`/home/user`) and virtual (`/home/user.linux`) environments.
- **Re-add External Desktop Inputs**: Restore `mangowc` as a flake input to enable the "retroism" desktop environment.

## Capabilities

### New Capabilities
- `nixos-common-layer`: Core system settings required by every NixOS host.
- `nixos-lima-layer`: Specialized settings for virtualized Lima environments.
- `nixos-desktop-layer`: Full desktop suite (Mangowc, Waybar, Greetd, PipeWire) following the "retroism" aesthetic.
- `physical-hardware-support`: Capability to define and apply host-specific hardware configurations (NVIDIA drivers, disk UUIDs).

### Modified Capabilities
- `nixos-builder`: Update the NixOS builder to distinguish between physical and virtual (Lima) hosts.

## Impact

- `hosts/default.nix`: Addition of the `arrakis` host definition.
- `lib/builders/nixos.nix`: Logic to handle physical vs. Lima systems.
- `modules/nixos/`: Significant reorganization and addition of system modules.
- `modules/darwin/system.nix`: Update to the `buildMachines` configuration.
