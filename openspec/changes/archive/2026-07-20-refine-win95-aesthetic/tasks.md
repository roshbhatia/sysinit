## 1. Theme and Configuration Fixes

- [x] 1.1 Update 'hosts/default.nix' to use 'windows-95' dark variant for 'arrakis'.
- [x] 1.2 (Already done) Copied SSH key to arrakis for Neovim config.
- [x] 1.3 Update 'modules/home/programs/wezterm/default.nix' to pass Stylix colors to 'config.json'.

## 2. Wezterm UI Refinement

- [x] 2.1 Refine window padding in 'modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua'.
- [x] 2.2 Implement custom tab bar styling using theme colors in 'ui.lua'.
- [x] 2.3 Adjust window decorations and title bar settings.

## 3. Validation

- [ ] 3.1 Evaluate and build configuration.
- [ ] 3.2 SSH into 'arrakis', pull, and switch.
- [ ] 3.3 Verify Neovim config is loaded and Wezterm UI looks cleaner in dark mode.
