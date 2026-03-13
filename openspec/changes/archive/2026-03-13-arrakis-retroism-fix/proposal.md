## Why

The initial "Retroism" overhaul on `arrakis` introduced several functional regressions: Wezterm crashes with a "nil field ansi" error, the Waybar menu bar is missing, and applications are often invisible. This change addresses these critical glue-layer issues while fully realizing the 90s aesthetic with appropriate bitmap fonts and robust session management.

## What Changes

- **Complete Wezterm Palette**: Update the `classic-platinum` theme to include the full ANSI and Brights color arrays, resolving the "nil field ansi" crash.
- **Robust Session Signaling**: Fix the `mango-wrapped` script to explicitly trigger the `mango-session.target`, ensuring all user services (Waybar, Mako) start reliably.
- **Waybar Visibility Fix**: Adjust Waybar configuration to use `layer: top` and `exclusive: true` to prevent it from being hidden by the gapless tiling.
- **Terminus Bitmap Font**: Deploy and enforce `Terminus (Nerd Font)` as the system-wide monospace font for maximum 90s clarity.
- **Improved Autostart**: Refine the `mangowc` autostart sequence to ensure the background daemon and bar are initialized in the correct order.

## Capabilities

### New Capabilities
- `bitmap-font-support`: System-wide support and configuration for high-legibility bitmap fonts.

### Modified Capabilities
- `robust-wayland-session`: Improve the session activation reliability and environment propagation.
- `classic-platinum-theme`: Complete the color palette mapping for specialized applications like Wezterm.

## Impact

- `modules/lib/theme/adapters/wezterm.nix` (or where theme is handled): Addition of ANSI blocks.
- `modules/nixos/desktop/wayland.nix`: Update to wrapper script logic.
- `modules/nixos/home/desktop.nix`: Waybar and font configuration refinements.
- `hosts/default.nix`: Update to `arrakis` font selection.
