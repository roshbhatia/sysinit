## Why

The current desktop environment on `arrakis` is unstable: `mangowc` fails to trigger the full user session, `wezterm` is missing from the Linux environment, and applications are not visible due to environment propagation issues. This change stabilizes the GUI by ensuring proper session activation, making key applications cross-platform, and refining visual assets.

## What Changes

- **Enable Cross-Platform Wezterm**: Move the `wezterm` module from Darwin-specific to shared home programs.
- **Robust Session Activation**: Wrap the `mangowc` launch in a script that correctly exports the Wayland environment to `dbus` and `systemd`.
- **Refined Assets**: Fetch and deploy the "retroism" wallpaper directly from the source repository.
- **Environment Propagation**: Ensure `XDG_RUNTIME_DIR` and other critical variables are available to all launched applications.

## Capabilities

### New Capabilities
- `cross-platform-terminal`: Unified terminal configuration available on both Darwin and NixOS.
- `robust-wayland-session`: Standardized session activation pattern for Wayland compositors on NixOS.

### Modified Capabilities
- `nixos-desktop-layer`: Improve stability and asset management for the desktop layer.

## Impact

- `modules/darwin/home/default.nix`: Removal of `wezterm` import.
- `modules/home/programs/`: New location for the `wezterm` module.
- `modules/nixos/home/desktop.nix`: Updated `mangowc` and wallpaper configuration.
- `modules/nixos/desktop/wayland.nix`: Improved session wrapping logic.
