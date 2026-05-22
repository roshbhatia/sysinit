## 1. Built-in Extensions

- [x] 1.1 Add `model-status`, `preset`, `trigger-compact`, `input-transform`, `minimal-mode`, `mac-system-theme`, `reload-runtime` to the `extensions = [ ... ]` list in `pi.nix`
- [x] 1.2 Verify all 7 extension `.ts` files exist at the pinned `piExtensionsSrc` rev (`85d06052fbee...`)

## 2. npm Package Additions

- [x] 2.1 Add `piPkgVim` derivation for `@sysid/pi-vim` v1.0.3 using `pkgs.fetchzip` (scoped package — uses fetchzip directly with full URL)
- [x] 2.2 Add `piPkgToolDisplay` derivation for `pi-tool-display` v0.3.1 using `fetchNpmPkg`
- [x] 2.3 Add `piPkgSubdirContext` derivation for `pi-subdir-context` v1.1.2 using `fetchNpmPkg`
- [x] 2.4 Add `piCosts` derivation for `@psg2/pi-costs` v1.0.1 and include in `home.packages`
- [x] 2.5 Add all three new packages (`piPkgVim`, `piPkgToolDisplay`, `piPkgSubdirContext`) to `piPackagesJson`

## 3. pi-context Upgrade

- [x] 3.1 Replace `piPkgContext` git fetch derivation with `fetchNpmPkg { name = "pi-context"; version = "1.1.2"; hash = "..."; }`
- [x] 3.2 Compute and set the correct `hash` for pi-context v1.1.2 npm tgz

## 4. Fast External Editor

- [x] 4.1 Add `nvimPi = pkgs.writeShellScriptBin "nvim-pi" "exec nvim --clean -c 'set ft=markdown' \"$@\""` in the `let` block
- [x] 4.2 Add `nvimPi` to `home.packages`
- [x] 4.3 Set `sessionVariables.VISUAL = "${nvimPi}/bin/nvim-pi"` so pi's externalEditor (Ctrl+E) uses the fast wrapper

## 5. Verification

- [x] 5.1 Run `nix build` (or `darwin-rebuild build`) and confirm no hash mismatches
- [ ] 5.2 Confirm `nvim-pi` is on PATH and starts without plugin load delay
- [ ] 5.3 Confirm all 7 new extension files are present in `~/.pi/agent/extensions/` after activation
