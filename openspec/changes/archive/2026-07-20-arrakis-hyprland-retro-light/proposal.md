## Why

The current mangowc setup on arrakis is unstable, leading to rendering glitches, missing UI components, and a 'cutoff' appearance in Wezterm. Switching to Hyprland provides a more robust and feature-rich foundation for the retro aesthetic. Reverting to Windows 95 Light and using high-quality bitmap/pixel fonts will achieve the authentic 90s look the user desires.

## What Changes

- **Switch Window Manager**: Replace mangowc with Hyprland for improved stability and NVIDIA compatibility.
- **Aesthetic Shift**: Switch arrakis back to Windows 95 Light mode for an authentic 90s feel.
- **New Wallpaper**: Set the background to the provided high-resolution retro image.
- **Application Searcher**: Integrate Rofi (Wayland) with a clean, centered theme inspired by Sly-Harvey.
- **Font Update**: Transition to a more refined font (e.g., Maple Mono or a lighter variant of Fixedsys).
- **Wezterm UI Polish**: Fix the 'cutoff' issue by refining padding and styling the window frame/tab bar to look like a classic title bar.
- **Neovim Fix**: Ensure Neovim uses the system config by enabling Stylix integration and verifying the config path.

## Capabilities

### New Capabilities
- hyprland-desktop: Support for the Hyprland window manager and its associated ecosystem.
- rofi-application-searcher: Centered, themed application launcher using Rofi.

### Modified Capabilities
- nixos-desktop-layer: Transition from mangowc to Hyprland as the primary compositor.
- classic-platinum-theme: Replaced by windows-95 light variant.

## Impact

- modules/nixos/desktop/: Removal of mangowc, addition of Hyprland.
- modules/home/programs/: Addition of Rofi configuration.
- hosts/default.nix: Update arrakis theme, variant, and fonts.
- modules/home/programs/wezterm/: UI refinements and padding fixes.
