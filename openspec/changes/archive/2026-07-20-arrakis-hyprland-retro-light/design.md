## Context

The arrakis host requires a stable, visually polished retro desktop. Previous attempts with mangowc were glitchy. We will pivot to Hyprland while maintaining the Windows 95 Light aesthetic. We will also address Neovim config loading and Wezterm UI cutoffs.

## Goals / Non-Goals

**Goals:**
- Transition to Hyprland WM.
- Switch to windows-95 LIGHT theme.
- Fix Neovim and Wezterm UI issues.
- Implement a high-quality application searcher (Rofi).

## Decisions

### 1. Hyprland Integration
**Decision**: Use 'programs.hyprland.enable = true' in NixOS and configure it via Home Manager.
**Rationale**: Hyprland offers superior performance and customizability, especially for NVIDIA users on Wayland.

### 2. Windows 95 Light Scheme
**Decision**: Set arrakis back to 'variant = "light"' and 'appearance = "light"' for the windows-95 theme.
**Rationale**: Light mode is essential for the authentic 90s OS look (grey/teal/navy).

### 3. Rofi Searcher (Sly-Harvey style)
**Decision**: Configure 'rofi-wayland' with a centered UI and a theme that matches the Windows 95 palette.
**Rationale**: Provides a professional application launcher experience as requested.

### 4. Wezterm Frame and Padding
**Decision**: Increase 'top' padding and use 'INTEGRATED_BUTTONS' with custom colors to avoid the 'cutoff' look.
**Rationale**: Corrects the rendering artifacts and makes the window look more cohesive.

### 5. Neovim Stylix Integration
**Decision**: Set 'stylix.targets.neovim.enable = true'.
**Rationale**: Ensures Neovim picks up the system colorscheme and correctly identifies the base16 scheme.

## Risks / Trade-offs

- **[Risk]**: Hyprland might require more complex configuration than mangowc.
- **[Mitigation]**: We will start with a solid base configuration inspired by Frost-Phoenix and linux-retroism.
