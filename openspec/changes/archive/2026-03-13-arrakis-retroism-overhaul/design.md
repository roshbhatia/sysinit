## Context

The `arrakis` host uses an NVIDIA GPU with Wayland and the `mangowc` compositor. Current configuration enables modern effects like Gaussian blur and soft shadows, which are known to cause flickering and artifacts on NVIDIA. The user desires a "retro" look similar to the `linux-retroism` project, which aligns with disabling these problematic effects.

## Goals / Non-Goals

**Goals:**
- **Rock-Solid Rendering**: Eliminate artifacts by removing all transparency and blur layers.
- **Retro Aesthetic**: Achieve a 90s "Platinum" look using specific colors, sharp corners, and pixel-perfect fonts.
- **Modular Theming**: Define the aesthetic in a way that it can be applied to any NixOS desktop host while being driven by the `classic-platinum` palette.

**Non-Goals:**
- **Functional WM Change**: We will stick with `mangowc` and `waybar` rather than switching to `Hyprland` or `Quickshell` (used in the reference project) to maintain configuration continuity.

## Decisions

### 1. The "Classic Platinum" Palette
**Decision**: Create a new palette in `modules/lib/theme/palettes/classic-platinum.nix`.
- `base00`: `#CCCCCC` (Surface/Background)
- `base01`: `#999999` (Secondary Surface)
- `base02`: `#666666` (Muted/Selection)
- `base03`: `#333333` (Comments)
- `base04`: `#000000` (Foreground/Text)
- `base05`: `#000000` (Main Text)
- `base0D`: `#000080` (Active Accent - Navy Blue)

### 2. WM Sharpness Overrides
**Decision**: In `modules/nixos/home/desktop.nix`, force `mangowc` settings to "Retro Mode" by default:
- `blur = 0`
- `shadows = 0`
- `border_radius = 0`
- `animation_type = none`
- `gappih = 0`, `gappiv = 0`, `gappoh = 0`, `gappov = 0` (Flush windows)

### 3. Waybar "Menu Bar" Styling
**Decision**: Redesign the Waybar CSS to:
- Set `margin: 0` and `border-radius: 0`.
- Add a `border-bottom: 1px solid #000000`.
- Use a solid background color from the palette.
- Use a "NixOS" icon as the "Start" menu.

### 4. Component Homogenization
**Decision**: Update `fuzzel` and `mako` to inherit the `0px` radius and `1px` solid border style. This ensures the entire system follows the "blocky" design language.

## Risks / Trade-offs

- **[Risk]**: Terminus/Pixel fonts may look blurry if not sized correctly.
- **[Mitigation]**: Set explicit pixel sizes (e.g., 12px or 14px) and ensure `anti-aliasing` is handled correctly in fontconfig.
- **[Risk]**: 0px gaps might feel too crowded for some.
- **[Mitigation]**: Keep the implementation modular so gaps can be easily re-enabled if desired, though 0px is more "retro-authentic".
