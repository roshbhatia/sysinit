## 1. Wezterm and Palette Fixes

- [x] 1.1 Update `classic-platinum.yaml` to include dummy but valid ANSI/Brights sections if needed by the generator.
- [x] 1.2 Update the Wezterm theme logic to map Base16 colors to `ansi` and `brights` arrays.
- [x] 1.3 Verify Wezterm launches without Lua errors on `arrakis`.

## 2. Session and Bar Stabilization

- [x] 2.1 Update `mango-wrapped` in `modules/nixos/desktop/wayland.nix` to start `mango-session.target`.
- [x] 2.2 Add `exclusive = true;` and `layer = "top";` to Waybar config in `modules/nixos/home/desktop.nix`.
- [x] 2.3 Refine autostart to ensure Waybar and Mako launch only after the session target is active.

## 3. Font and Aesthetic Refinement

- [x] 3.1 Add `terminus_font` and `nerd-fonts.terminus` to the NixOS system fonts.
- [x] 3.2 Update `arrakis` host definition to use `Terminus (Nerd Font)` explicitly.
- [x] 3.3 Ensure antialiasing is disabled for Terminus in Wezterm and Waybar.

## 4. Validation

- [x] 4.1 Evaluate and build the configuration.
- [x] 4.2 Switch on `arrakis` and verify the bar is visible and exclusive.
- [x] 4.3 Confirm bitmap fonts are rendering sharply at 12px/14px.
