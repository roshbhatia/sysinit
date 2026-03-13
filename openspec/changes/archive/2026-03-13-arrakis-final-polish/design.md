## Context

The `arrakis` host is running a specialized retro-aesthetic configuration. Recent issues include a Wezterm crash (`nil field 'ansi'`) and a missing Waybar. Investigation reveals that the font family name for the Terminus Nerd Font is `Terminess Nerd Font`, and Wezterm's custom theme needs to be correctly registered in its Lua environment.

## Goals / Non-Goals

**Goals:**
- **Correct Font Mapping**: Set the system font to `Terminess Nerd Font`.
- **Fix Wezterm Theme**: Ensure the custom `classic-platinum-light` scheme is fully defined and loaded.
- **Restore Bar Visibility**: Ensure Waybar is visible and reserves space correctly.

## Decisions

### 1. Font Family Name Correction
**Decision**: Update `hosts/default.nix` to use `Terminess Nerd Font` instead of `Terminus (Nerd Font)`.
**Rationale**: `fc-list` confirms `Terminess Nerd Font` is the correct family name for the installed Nerd Font variant.

### 2. Wezterm Theme Registration
**Decision**: In `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua`, explicitly add the custom theme directory to the Wezterm search path or use a more robust loading method.
**Rationale**: Wezterm needs to know where to find the custom Lua theme file we are generating.

### 3. Waybar Layer Shell Tweaks
**Decision**: Set `exclusive: true` and `layer: top` in Waybar config.
**Rationale**: This ensures the bar sits above other windows and the compositor allocates space for it.

### 4. Zero Radius Enforcement
**Decision**: Audit all CSS and configuration files to ensure `border-radius: 0` is strictly enforced.

## Risks / Trade-offs

- **[Risk]**: `Terminess` naming might be specific to the Nerd Font package version.
- **[Mitigation]**: We've empirically verified the name on the actual host.
