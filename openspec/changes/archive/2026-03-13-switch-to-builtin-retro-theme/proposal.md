## Why

Instead of maintaining a custom `classic-platinum` theme and manual color mappings, switching to a built-in Base16 theme like `Windows 95 Light` ensures better compatibility between Stylix and Wezterm while simplifying the codebase. This leverages upstream maintenance for color accuracy and plugin support.

## What Changes

- **Switch `arrakis` Theme**: Update the host configuration to use the built-in `windows-95` theme.
- **Update Theme Mappings**: Add `windows-95` to the global Base16 and application-specific mappings.
- **Cleanup Custom Theme**: Remove the `classic-platinum` YAML, palette, and generated Wezterm Lua theme.
- **Simplify Wezterm Config**: Rely on Wezterm's built-in `Windows 95 Light (base16)` scheme instead of a manually generated file.

## Capabilities

### New Capabilities
- `builtin-retro-support`: Native support for industry-standard retro Base16 themes.

### Modified Capabilities
- `classic-platinum-theme`: **REMOVED** in favor of `windows-95`.

## Impact

- `modules/lib/theme/base16-mapping.nix`: Addition of `windows-95`.
- `modules/lib/theme/adapters/theme-names.nix`: Mapping for `windows-95`.
- `hosts/default.nix`: Update `arrakis` host.
- `modules/home/programs/wezterm/default.nix`: Removal of manual theme generation.
