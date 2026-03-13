## Why

Despite previous fixes, the `arrakis` host still experiences GUI glitches: Wezterm fails due to theme mapping errors, font family names are incorrect, and the Waybar menu bar is missing or occluded. This change provides the final glue and refinement needed to make the "Retroism" aesthetic fully functional and visually perfect.

## What Changes

- **Correct Font Family**: Update the system-wide font name from `Terminus (Nerd Font)` to `Terminess Nerd Font` to match the actual installed family name.
- **Wezterm Theme Fix**: Ensure Wezterm's custom `classic-platinum` theme is correctly registered and contains all required ANSI fields to prevent the "nil field ansi" crash.
- **Bar Recovery**: Force Waybar to be visible by refining its Layer Shell configuration and ensuring it handles tiling layout changes correctly.
- **Global Retro Overrides**: Ensure 0px radius and solid borders are consistently applied across all NixOS desktop components.

## Capabilities

### New Capabilities
- `system-wide-font-enforcement`: Reliable mapping of installed font packages to application-level family names.

### Modified Capabilities
- `retro-desktop-aesthetic`: Ensure consistent application of retro styles across all UI components.
- `classic-platinum-theme`: Fix application-specific theme failures (Wezterm).

## Impact

- `hosts/default.nix`: Update to `arrakis` font selection.
- `modules/home/programs/wezterm/`: Fixes to theme mapping and Lua config.
- `modules/nixos/home/desktop.nix`: Waybar and Mako styling refinements.
