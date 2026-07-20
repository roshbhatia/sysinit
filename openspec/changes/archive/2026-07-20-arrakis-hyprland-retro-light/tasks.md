## 1. Window Manager Transition

- [ ] 1.1 Create 'modules/nixos/desktop/hyprland.nix' and enable Hyprland.
- [ ] 1.2 Remove mangowc references from 'modules/nixos/desktop/wayland.nix' and 'greetd.nix'.
- [ ] 1.3 Create 'modules/home/programs/hyprland.nix' for user-level config (keybinds, rules).

## 2. Aesthetic and App Searcher

- [ ] 2.1 Update 'hosts/default.nix' to switch arrakis back to light mode and set the new wallpaper.
- [ ] 2.2 Create 'modules/home/programs/rofi.nix' with a centered retro theme.
- [ ] 2.3 Update 'modules/home/programs/default.nix' to import Hyprland and Rofi modules.

## 3. UI Polish and App Fixes

- [ ] 3.1 Refine Wezterm padding and frame in 'ui.lua' to fix cutoffs.
- [ ] 3.2 Enable Stylix for Neovim in 'modules/home/programs/neovim/default.nix'.
- [ ] 3.3 Verify Neovim config loading on arrakis.

## 4. Validation

- [ ] 4.1 Evaluate and build configuration.
- [ ] 4.2 SSH into 'arrakis' (when reachable), pull, and switch.
- [ ] 4.3 Verify Hyprland stability and the Windows 95 Light aesthetic.
