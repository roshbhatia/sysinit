## 1. Font and Theme Fixes

- [x] 1.1 Update `hosts/default.nix` to use `Terminess Nerd Font` for `arrakis`.
- [x] 1.2 Update `modules/home/programs/wezterm/default.nix` to explicitly include `ansi` and `brights` in the generated Lua theme.
- [x] 1.3 Ensure `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua` correctly loads the custom theme from the `colors/` directory.

## 2. Desktop Refinements

- [x] 2.1 Update `modules/nixos/home/desktop.nix` Waybar config: set `exclusive: true` and `layer: top`.
- [x] 2.2 Audit `modules/nixos/home/desktop.nix` to ensure `border-radius: 0` is applied to all components (Waybar, Mako, Fuzzel).
- [x] 2.3 Refine `mango-wrapped` script to ensure `systemctl --user start mango-session.target` is reliable.

## 3. Validation

- [x] 3.1 Evaluate and build the configuration.
- [x] 3.2 SSH into `arrakis`, pull changes, and switch.
- [x] 3.3 Verify Wezterm launches without errors and Waybar is visible.
