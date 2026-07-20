## Why

The current Windows 95 aesthetic on arrakis is incomplete and feels unpolished. The light theme can be jarring in certain environments, the Wezterm window frame and padding need refinement to look cleaner, and the Neovim configuration is failing to load on arrakis due to SSH key issues with the private config repo. Switching to a dark theme and fixing the integration glue will provide a much better user experience.

## What Changes

- **Switch to Windows 95 Dark**: Change the default theme for arrakis to the dark variant of the Windows 95 Base16 scheme.
- **Fix Neovim Configuration**: Switch the Neovim config repository URL from SSH to HTTPS to allow cloning without an SSH key on arrakis.
- **Refine Wezterm UI**:
    - Improve window padding for a cleaner look.
    - Style the window frame (tab bar) to better mimic a classic OS title bar area using the theme's palette.
    - Adjust font sizes and rendering flags for better clarity.
- **Stylix Integration**: Ensure the Base16 palette is available to the Wezterm Lua configuration for advanced UI styling.

## Capabilities

### New Capabilities
- wezterm-ui-refinement: Advanced UI styling for Wezterm, including custom tab bar and frame styling.

### Modified Capabilities
- classic-platinum-theme: **REMOVED** previously, now fully adopting windows-95.
- retro-desktop-aesthetic: Refine the retro aesthetic with dark mode and better UI components.

## Impact

- hosts/default.nix: Update arrakis to dark variant.
- modules/home/programs/neovim/default.nix: Update repo URL to HTTPS.
- modules/home/programs/wezterm/default.nix: Pass Stylix colors to config.json.
- modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua: Implement UI refinements.
