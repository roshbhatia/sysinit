## 1. Theme and Palette Setup

- [x] 1.1 Create `modules/lib/theme/palettes/classic-platinum.nix` with the Base16 colors.
- [x] 1.2 Update `modules/lib/theme/metadata.nix` to include the `classic-platinum` theme.
- [x] 1.3 Add `classic-platinum` to the Base16 mapping in `modules/lib/theme/base16-mapping.nix`.

## 2. Desktop Configuration Overhaul

- [x] 2.1 Update `modules/nixos/home/desktop.nix` to disable blur, shadows, and animations in `mangowc`.
- [x] 2.2 Set `mangowc` border radius to 0, border size to 1, and gaps to 0.
- [x] 2.3 Redesign `Waybar` style to be a flush menu bar with 1px bottom border and solid background.
- [x] 2.4 Update `fuzzel` and `mako` configurations to use 0px radius and solid borders.

## 3. Host and Component Alignment

- [x] 3.1 Update `hosts/default.nix` to set `arrakis` theme to `classic-platinum`.
- [x] 3.2 Update `arrakis` host font settings to use `Terminus`.
- [x] 3.3 Ensure the new desktop defaults are applied to all NixOS desktop hosts.

## 4. Validation

- [x] 4.1 Evaluate the `arrakis` configuration to check for Nix errors.
- [x] 4.2 Switch to the new configuration on `arrakis` and verify visual stability.
- [x] 4.3 Confirm the absence of rendering artifacts on the NVIDIA GPU.
