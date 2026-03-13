## 1. Theme Mapping Updates

- [x] 1.1 Add `windows-95` to `modules/lib/theme/base16-mapping.nix`.
- [x] 1.2 Add `windows-95` to `modules/lib/theme/adapters/theme-names.nix`.
- [x] 1.3 Update `hosts/default.nix` to use `windows-95` for `arrakis`.

## 2. Cleanup and Simplification

- [x] 2.1 Remove `modules/lib/theme/palettes/classic-platinum.nix`.
- [x] 2.2 Remove `modules/lib/theme/custom-schemes/classic-platinum.yaml`.
- [x] 2.3 Update `modules/home/programs/wezterm/default.nix` to remove the manual `classic-platinum-light.lua` generation.
- [x] 2.4 Update `modules/lib/theme/metadata.nix` to remove `classic-platinum`.

## 3. Validation

- [ ] 3.1 Evaluate and build configuration.
- [ ] 3.2 SSH into `arrakis`, pull, and switch.
- [ ] 3.3 Verify the new built-in theme looks correct in Wezterm and Waybar.
