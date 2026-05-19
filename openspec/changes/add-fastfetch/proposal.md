## Why

The repo no longer ships a system-information fetch tool. `macchina` was
removed alongside the configurations flatten in commit `aef318858`
("yamlhatred"), taking the six ASCII art files (`rosh`, `rosh-color`, `nix`,
`mgs`, `vagabond`, `varre`) with it. The user wants `fastfetch` instead —
faster, actively maintained, native macOS sensor support, and structured
JSONC config — modeled on
[dededecline/dotfiles/fastfetch](https://github.com/dededecline/dotfiles/tree/main/fastfetch),
but declared through the home-manager `programs.fastfetch` module rather than
imperative `xdg.configFile` writes. The work-host (`demiurge`) gets its own
art slot named `laurel`, seeded with dede's `hera` logo.

## What Changes

- New home-manager module at `modules/home/programs/fastfetch.nix` enabling
  `programs.fastfetch` with a `settings` attrset that mirrors dede's module
  layout: `title → Hardware → Firmware → Software → Theme → Network →
  colors`, hex-key colors per cluster, `~> ` separator, and `logo.type =
  "file"` pointing at `${config.xdg.configHome}/fastfetch/logo.txt`.
- Key colors are sourced from `config.lib.stylix.colors.base*` instead of
  dede's Catppuccin literals, matching how `fzf.nix` / `helix.nix` /
  `nushell.nix` already consume the active palette. The `logo.color.1` is
  also stylix-derived so the art recolors with the rest of the system.
- Restore the five reusable macchina art files under
  `modules/home/programs/fastfetch/art/{rosh,rosh-color,nix,mgs,vagabond,varre}.txt`
  (recovered verbatim from `aef318858^`).
- Add a new `laurel.txt` art file under the same dir, contents identical to
  dede's `logo_hera.txt`.
- Module installs all art files into `${xdg.configHome}/fastfetch/art/` via
  `xdg.configFile`, then materializes the active selection at
  `${xdg.configHome}/fastfetch/logo.txt` (the path the home-manager-managed
  config references). Selection is hostname-driven with a per-host default
  override.
- Wire the new module into `modules/home/programs/default.nix` (alphabetical
  position between `./eza.nix` and `./fd.nix`).
- Hostname → default art mapping:
  - `lv426` (personal darwin) → `rosh`
  - `demiurge` (work darwin) → `laurel`
  - `arrakis` (personal nixos) → `nix`
  - `nostromo` (lima nixos) → `nix`
  - any other host falls back to `rosh`
- macOS-only `Software` cluster keeps dede's brew/cask/mas package-count
  shell-out as-is. The Linux variant substitutes a `nix-store -q
  --requisites /run/current-system | wc -l` count and drops the
  `terminalfont` / display sections that read AppleScript-only paths.

### Non-goals

- **No `macchina` revival.** The package is not added back; `fastfetch`
  fully replaces it. Old `macchina` TOML themes are not ported.
- **No greeter / login integration.** The module declares the binary +
  config only; nothing auto-runs `fastfetch` on shell start. The user can
  add `fastfetch` to their `~/.zshrc` interactively if they want; this
  change does not edit `modules/home/programs/zsh/`.
- **No new capabilities for theming or font discovery.** Existing
  stylix-via-`config.lib.stylix` is the only theming path; no new theme
  abstraction is introduced.
- **No vendoring of upstream fastfetch logos.** Only the six restored
  macchina arts plus `laurel.txt` (which equals dede's `hera`, attributed
  in the file header) ship in-repo.
- **No `programs.fastfetch.settings` per-host divergence beyond the art
  pointer.** The module body is identical across hosts; only
  `xdg.configFile."fastfetch/logo.txt".source` varies.

## Capabilities

### New Capabilities

- `fastfetch-config`: declares that `fastfetch` is enabled via the
  home-manager `programs.fastfetch` module; its `settings` are Nix-derived
  (not hand-written JSONC) and consume stylix base16 colors; the active
  art file is selected by hostname against a fixed map; the six restored
  macchina arts plus `laurel` ship in-repo under
  `modules/home/programs/fastfetch/art/`; Darwin and Linux hosts get
  platform-appropriate `Software` modules.

### Modified Capabilities

<!-- None — no existing spec defines fastfetch or fetch-tool behavior. -->

## Impact

- **Affected files**:
  - new: `modules/home/programs/fastfetch.nix`
  - new dir: `modules/home/programs/fastfetch/art/` with seven `.txt` files
  - edit: `modules/home/programs/default.nix` (one `imports` line)
- **Pattern reuse**: directly mirrors the `helix.nix` / `fzf.nix` shape —
  `{ config, pkgs, lib, ... }: { programs.<tool> = { enable = true;
  settings = { ... }; }; xdg.configFile."<tool>/..." = { source = ...; };
  }`. No new infrastructure introduced. Hostname dispatch reuses
  `osConfig.networking.hostName` (Darwin) / `config.networking.hostName`
  (NixOS) the same way `modules/home/programs/ssh.nix` already does.
- **Impactful actions requiring human verification**:
  - `nh os switch` on each active host (`lv426`, `demiurge`, `arrakis`) to
    confirm the right art renders and stylix colors land. `nh os build`
    catches type errors but cannot validate the rendered output.
- **Gating signal**: standard `nh os build` (validate closure) →
  `nh os switch` (apply). Reverting is a single `git revert` since no
  other module depends on `fastfetch.nix`.
- **Progressive rollout**: three slices in `tasks.md` — (1) module + art
  files + import; (2) hostname dispatch + stylix wiring; (3) per-host
  verification. Each slice is independently revertible.
