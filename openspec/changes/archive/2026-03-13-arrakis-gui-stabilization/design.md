## Context

The `arrakis` host is running a `mangowc` session via `greetd`. However, the current setup doesn't correctly inform the user's `systemd` instance or `dbus` about the Wayland environment, leading to a "dead" `mango-session.target` and invisible applications. Additionally, the move of `wezterm` to Darwin-only has left the Linux environment without its primary terminal.

## Goals / Non-Goals

**Goals:**
- **Standardize Wezterm**: Restore `wezterm` to NixOS by moving it to a shared location.
- **Activate Session**: Ensure `mango-session.target` reaches an active state.
- **Visible Apps**: Guarantee that Wayland clients (Waybar, Mako, Wezterm) can connect to the compositor.
- **Aesthetic Assets**: Switch to the requested "copyleft" retro wallpaper.

**Non-Goals:**
- **Changing Compositor**: We remain on `mangowc`.
- **Reinstalling OS**: All fixes are configuration-based.

## Decisions

### 1. Unified `wezterm` Module
**Decision**: Relocate `modules/darwin/home/wezterm` to `modules/home/programs/wezterm`.
**Rationale**: Terminal configuration is 95% shared between platforms (Lua config, themes). Platform-specific overrides can be handled within the module if needed.

### 2. The `mango-wrapped` Pattern
**Decision**: Create a wrapper script for `mangowc` that runs `dbus-update-activation-environment --systemd --all` before starting the compositor.
**Rationale**: This is the industry-standard way to ensure that systemd user services and dbus-activated apps (like portals) know which Wayland display to use.

### 3. Retro Wallpaper Retrieval
**Decision**: Use `pkgs.fetchurl` to pull `https://raw.githubusercontent.com/diinki/linux-retroism/main/wallpapers/copyleft.png`.
**Rationale**: Hardcoding the URL in Nix ensures the asset is managed in the Nix store and available offline after the first build.

### 4. Correcting `greetd` Command
**Decision**: Update `modules/nixos/desktop/greetd.nix` to call the `mango-wrapped` script instead of the raw `mango` binary.

## Risks / Trade-offs

- **[Risk]**: Path changes for `wezterm` might break existing symlinks on Darwin.
- **[Mitigation]**: Home-manager handles link updates automatically during the next `switch`.
- **[Risk]**: `fetchurl` might fail if the remote repo becomes private or deleted.
- **[Mitigation]**: The asset will be cached in the user's Nix store and the project's binary caches.
