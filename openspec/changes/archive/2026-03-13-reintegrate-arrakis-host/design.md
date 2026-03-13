## Context

The current `sysinit` NixOS configuration is heavily biased towards Lima VMs (`nostromo`). This includes hardcoded home directory paths (`/home/user.linux`), mandatory inclusion of the `nixos-lima` module, and a lack of support for physical system components like bootloaders (GRUB/Systemd-boot), specialized networking, and hardware drivers (NVIDIA).

## Goals / Non-Goals

**Goals:**
- **Dynamic Host Detection**: Automatically adjust home directories and system modules based on whether the host is physical or a Lima VM.
- **Hardware Abstraction**: Create a clean interface for host-specific hardware configurations (NVIDIA drivers, disk UUIDs).
- **Module Parity**: Restructure `modules/nixos/` to match the flat, modular pattern used in `modules/darwin/`.
- **Re-enable Arrakis**: Restore the `arrakis` host with its previous configuration but adapted to the new `values` pattern.

**Non-Goals:**
- **OS Re-installation**: This design focuses on the Nix configuration, not the physical OS installation process.
- **Non-x86_64/aarch64 Support**: We remain focused on the current architectures (Apple Silicon and x86_64 desktops).

## Decisions

### 1. Three-Tier Modular Structure in `modules/nixos/`
**Decision**: Reorganize `modules/nixos/` into logical sub-directories:
- `modules/nixos/common/`: Core settings imported by all hosts (SSH, User, Nix settings, Shells).
- `modules/nixos/lima/`: Specialization for virtual hosts (Mounts, Lima guest agent, Auto-login).
- `modules/nixos/desktop/`: GUI components (Mangowc, Waybar, Greetd, PipeWire, Gaming).
- `modules/nixos/hardware/`: Physical host hardware configurations (Disk UUIDs, GPU drivers).

**Rationale**: Composable tiers allow for tailored host configurations.
**Alternatives**: Monolithic files with complex `if-then-else` blocks (hard to test).

### 2. Host Configuration Composition
**Decision**: Update the `arrakis` host to opt-in to `common` and `desktop`, while `nostromo` (Lima) opts-in to `common` and `lima`.
**Rationale**: Clear separation between virtualized and desktop environments.
**Alternatives**: Auto-detection (less predictable).

### 3. Home Directory Normalization
**Decision**: Pass an `isLima` flag in `values` from the builder. Update `modules/nixos/home-manager.nix` and `modules/home/default.nix` to use this flag to set the home path correctly.
**Rationale**: Lima's `.linux` home directory suffix is required to avoid mounting conflicts with the host `/Users`.
**Alternatives**: Unifying home paths (breaks Lima workflow).

### 4. Restore "Retroism" Desktop
**Decision**: Re-add the `mangowc` input (`github:DreamMaoMao/mangowc`) and implement its home-manager module within the `desktop/` tier.
**Rationale**: Restores the user's specific visual and workflow environment.
**Alternatives**: Replacing with generic Sway/Hyprland (diverges from user's intent).

## Risks / Trade-offs

- **[Risk]**: NVIDIA drivers on x86_64 vs. aarch64.
- **[Mitigation]**: Ensure `desktop/` hardware settings are guarded by platform/host checks.
- **[Risk]**: Incorrect build machine architecture in Darwin.
- **[Mitigation]**: Fix `arrakis` entry in `modules/darwin/system.nix` to `x86_64-linux`.
