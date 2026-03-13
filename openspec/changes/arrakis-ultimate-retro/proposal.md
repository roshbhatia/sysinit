## Why

The current retro implementation on `arrakis` is non-functional: Wezterm crashes due to incomplete theme registration, the Waybar configuration has syntax errors, and the font choice needs more 90s character. This change provides the definitive fix for the GUI session and aesthetic.

## What Changes

- **Switch to Fixedsys Font**: Replace Terminus with `Fixedsys Excelsior` for a more authentic 90s PC feel.
- **Fix Wezterm Theme Engine**: Explicitly register the `classic-platinum` theme in Wezterm's internal color scheme registry to prevent plugin crashes.
- **Waybar Workspace Fix**: Correct the Waybar configuration to properly display workspace labels without triggering argument errors.
- **UI Bevelling**: Apply classic 90s bevelled border styles to the bar and notifications.
- **Session Cleanup**: Consolidate autostart logic to prevent redundant service launches.

## Capabilities

### New Capabilities
- `retro-bevel-styling`: Standardized CSS for achieving 90s-style bevelled UI components.

### Modified Capabilities
- `nixos-desktop-layer`: Improve robustness of the autostart and session management.
- `classic-platinum-theme`: Ensure the theme is fully usable by all Wezterm plugins.

## Impact

- `modules/nixos/common/default.nix`: Addition of `fixedsys-excelsior`.
- `hosts/default.nix`: Update `arrakis` font.
- `modules/home/programs/wezterm/`: Fixes to theme registration and safety.
- `modules/nixos/home/desktop.nix`: Waybar and autostart overhaul.
