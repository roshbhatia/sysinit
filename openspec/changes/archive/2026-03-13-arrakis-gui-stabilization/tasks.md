## 1. Wezterm Normalization

- [x] 1.1 Move `modules/darwin/home/wezterm` to `modules/home/programs/wezterm`.
- [x] 1.2 Update `modules/darwin/home/default.nix` to remove the local `wezterm` import.
- [x] 1.3 Add `./wezterm` to the imports in `modules/home/programs/default.nix`.
- [x] 1.4 Update `wezterm` module to handle NixOS package installation (it's already in `darwinConfigs`).

## 2. Session Stabilization

- [x] 2.1 Update `modules/nixos/desktop/wayland.nix` to include a `mango-wrapped` script.
- [x] 2.2 Add `dbus-update-activation-environment --systemd --all` to the session startup.
- [x] 2.3 Update `modules/nixos/desktop/greetd.nix` to launch the wrapped session.
- [x] 2.4 Ensure `mango-session.target` is correctly reached in the autostart.

## 3. Visual Assets

- [x] 3.1 Update `modules/nixos/home/desktop.nix` to fetch the "copyleft" wallpaper from GitHub.
- [x] 3.2 Update the `swww` autostart command to use the new wallpaper path.

## 4. Validation

- [x] 4.1 Verify `wezterm` is available on both `lv426` (Darwin) and `arrakis` (NixOS).
- [x] 4.2 Confirm `mango-session.target` is active on `arrakis` after login.
- [x] 4.3 Verify the new wallpaper is rendered correctly.
