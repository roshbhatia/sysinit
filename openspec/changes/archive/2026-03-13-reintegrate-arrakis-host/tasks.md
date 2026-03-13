## 1. Directory Restructuring

- [x] 1.1 Create `modules/nixos/common/` and migrate base settings (User, SSH, Nix settings).
- [x] 1.2 Move existing `modules/nixos/lima.nix` to `modules/nixos/lima/default.nix`.
- [x] 1.3 Create `modules/nixos/desktop/` and restore `audio.nix`, `greetd.nix`, and `wayland.nix` (Mangowc).

## 2. Infrastructure Updates

- [x] 2.1 Re-add `mangowc` input to `flake.nix` and `flake.lock`.
- [x] 2.2 Update `lib/builders.nix` and `lib/builders/nixos.nix` to set and pass the `isLima` flag.
- [x] 2.3 Correct `arrakis` build machine architecture in `modules/darwin/system.nix` (`x86_64-linux`).
- [x] 2.4 Add the `arrakis` host back to `hosts/default.nix`.

## 3. Implementation

- [x] 3.1 Refactor `modules/nixos/default.nix` for tier-based imports.
- [x] 3.2 Update `modules/nixos/home-manager.nix` to use the dynamic home path.
- [x] 3.3 Create `modules/nixos/hardware/arrakis.nix` using the old UUIDs and NVIDIA config.
- [x] 3.4 Restore the `desktop` configuration in `modules/nixos/desktop/` and `modules/nixos/home/desktop.nix`.

## 4. Validation

- [x] 4.1 Build and test `arrakis` (`x86_64-linux`).
- [x] 4.2 Build and test `nostromo` (Lima) (confirm no regressions).
- [x] 4.3 Verify `arrakis` is usable as a remote build machine for the Mac.
