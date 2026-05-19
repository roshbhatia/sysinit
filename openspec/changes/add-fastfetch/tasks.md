## 1. Restore art assets

- [x] 1.1 Create directory `modules/home/programs/fastfetch/art/` (parallels the per-tool subdir pattern, e.g. `modules/home/programs/git/`)
- [x] 1.2 Recover and write `art/rosh.txt` from `git show aef318858^:modules/home/configurations/macchina/themes/rosh.ascii` (byte-identical, renamed `.ascii` → `.txt`)
- [x] 1.3 Recover and write `art/rosh-color.txt` from the same commit (carries embedded ANSI; preserve exact bytes)
- [x] 1.4 Recover and write `art/nix.txt` from the same commit
- [x] 1.5 Recover and write `art/mgs.txt` from the same commit
- [x] 1.6 Recover and write `art/vagabond.txt` from the same commit
- [x] 1.7 Recover and write `art/varre.txt` from the same commit
- [x] 1.8 Write `art/laurel.txt` as `# attribution: dededecline/dotfiles logo_hera\n` followed by the bytes of `dededecline/dotfiles@main:fastfetch/logo_hera.txt`
- [x] 1.9 Verify: `wc -l modules/home/programs/fastfetch/art/*.txt` shows non-empty files; `head -1 art/laurel.txt` shows the attribution comment

## 2. Author the module

- [x] 2.1 Create `modules/home/programs/fastfetch.nix` (follows the `{ config, pkgs, lib, ... }: { programs.<tool> = { enable = true; settings = {...}; }; xdg.configFile.<...> = { source = ...; }; }` shape from `modules/home/programs/fzf.nix` and `modules/home/programs/helix.nix`)
- [x] 2.2 Define a `let`-bound `sgr` helper that takes a base16 attribute name and returns `"38;2;${r};${g};${b}"` using `config.lib.stylix.colors."<base>-rgb-{r,g,b}"` decimal channels
- [x] 2.3 Define the hostname → art-name attrset (`lv426 → rosh`, `demiurge → laurel`, `arrakis → nix`, `nostromo → nix`) with `or "rosh"` fallback
- [x] 2.4 Read hostname as `osConfig.networking.hostName or config.networking.hostName or "unknown"` (matches the pattern in `modules/home/programs/ssh.nix`)
- [x] 2.5 Build the `softwareModules` list with `lib.optionals pkgs.stdenv.isDarwin [ ... ]` and `lib.optionals pkgs.stdenv.isLinux [ ... ]` per design.md Decision 5
- [x] 2.6 Build the `themeModules` list with the `defaults read -g AppleInterfaceStyle` line guarded by `lib.optionals pkgs.stdenv.isDarwin`
- [x] 2.7 Compose `programs.fastfetch.settings` with `$schema`, `display`, `logo`, and `modules` (title, breaks, five clusters in order, terminal `colors` block)
- [x] 2.8 Wire `xdg.configFile."fastfetch/art/<name>.txt".source = ./fastfetch/art/<name>.txt` for all seven files
- [x] 2.9 Wire `xdg.configFile."fastfetch/logo.txt".source = ./fastfetch/art/${artName}.txt` (the active selection)
- [x] 2.10 Set `programs.fastfetch.settings.logo.source = "${config.xdg.configHome}/fastfetch/logo.txt"`

## 3. Wire the import

- [x] 3.1 Edit `modules/home/programs/default.nix`: add `./fastfetch.nix` to `imports` alphabetically between `./eza.nix` and `./fd.nix`
- [x] 3.2 Run `nix fmt` on the edited files

## 4. Local build verification (no system change)

- [x] 4.1 Verify: `nix flake check` succeeds (catches type errors in the new module)
- [x] 4.2 Verify: `nh darwin build` succeeds on the current host (`demiurge`)
- [x] 4.3 Verify: inspect the produced `home-files/.config/fastfetch/config.jsonc` in the closure store path — every `keyColor` matches `^38;2;\d{1,3};\d{1,3};\d{1,3}$`, cluster order is Hardware → Firmware → Software → Theme → Network, `logo.source = "/Users/roshan/.config/fastfetch/logo.txt"`
- [x] 4.4 Verify: `home-files/.config/fastfetch/art/` contains all seven files (laurel, mgs, nix, rosh, rosh-color, vagabond, varre)
- [x] 4.5 Verify: `home-files/.config/fastfetch/logo.txt` symlinks to `hm_laurel.txt` (demiurge); first line is the attribution comment

## 5. Apply on local host

- [ ] 5.1 Apply: `nh os switch` on the local development host
- [ ] 5.2 Confirm: run `fastfetch`; verify the expected art renders, all five clusters appear, separator is ` ~> `, colors look correct against the active stylix theme
- [ ] 5.3 Confirm: re-run `fastfetch` a second time; output is identical (no transient errors from brew/cask/mas counters)

## 6. Apply on remaining active hosts

- [ ] 6.1 Verify: on `demiurge`, pull the change and run `nh os build`; closure builds; `home-files/.config/fastfetch/logo.txt` resolves to `laurel.txt`
- [ ] 6.2 Apply: `nh os switch` on `demiurge`
- [ ] 6.3 Confirm: run `fastfetch` on `demiurge`; the laurel/hera art renders, package count shows brew/cask/mas
- [ ] 6.4 Verify: on `arrakis`, pull and run `nh os build`; closure builds; `Software` cluster command is the `nix-store` variant
- [ ] 6.5 Apply: `nh os switch` on `arrakis`
- [ ] 6.6 Confirm: run `fastfetch` on `arrakis`; the `nix` art renders, package count shows a single `N (nix-store)` value
- [ ] 6.7 Confirm (optional, if user runs nostromo): `nh os switch` on `nostromo`, run `fastfetch`, verify `nix` art renders inside the lima VM

## 7. Closeout

- [ ] 7.1 Stage and propose a commit message (do not commit) in the form `feat(fastfetch): add home-manager module with macchina art + laurel for demiurge`
- [ ] 7.2 After user-confirmed commit and merge, run `/opsx:archive` to archive the change and merge the `fastfetch-config` spec into `openspec/specs/`
