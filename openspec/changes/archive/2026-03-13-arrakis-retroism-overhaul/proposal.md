## Why

The current desktop environment on the `arrakis` host suffers from visual artifacts and "bizarre" border rendering, primarily due to conflicts between modern Wayland effects (blur, soft shadows) and NVIDIA drivers. Adopting a "Retroism" (90s Classic Platinum) aesthetic provides a more stable, high-performance, and visually cohesive environment while embracing a unique retro-tech style.

## What Changes

- **New "Classic Platinum" Theme**: Introduce a custom Base16 colorscheme inspired by 90s operating systems (grey, navy, black).
- **Retro WM Configuration**: Update `mangowc` to use 0px corner radius, solid 1px borders, and zero gaps.
- **Artifact-Free Rendering**: Disable blur, shadows, and window animations to resolve NVIDIA driver rendering bugs.
- **Menu Bar Overhaul**: Re-style `Waybar` to sit flush at the top with a solid background and 1px bottom border, mimicking a classic OS menu bar.
- **Component Alignment**: Sync `fuzzel`, `mako`, and other UI elements to the blocky, non-rounded retro aesthetic.
- **Bitmap Font Integration**: Switch to `Terminus` or similar pixel fonts for improved clarity and aesthetic consistency.

## Capabilities

### New Capabilities
- `retro-desktop-aesthetic`: A global "retro" style for NixOS desktops, characterized by non-rounded corners, solid borders, and disabled transparency effects.
- `classic-platinum-theme`: A new system-wide theme palette following the 90s Platinum UI style.

### Modified Capabilities
- `nixos-desktop-layer`: Update the desktop layer to follow the retro aesthetic by default.

## Impact

- `modules/lib/theme/`: Addition of the `classic-platinum` palette.
- `modules/nixos/home/desktop.nix`: Comprehensive updates to `mangowc`, `waybar`, `fuzzel`, and `mako` configurations.
- `hosts/default.nix`: Update `arrakis` to use the new theme and font settings.
