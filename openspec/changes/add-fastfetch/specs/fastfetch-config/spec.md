## ADDED Requirements

### Requirement: fastfetch is enabled via the home-manager module

The repo SHALL enable `fastfetch` through the upstream
`programs.fastfetch` home-manager module, with `programs.fastfetch.enable
= true` and a Nix-rendered `programs.fastfetch.settings` attrset. The
module body SHALL live at `modules/home/programs/fastfetch.nix` and be
imported via `modules/home/programs/default.nix` alphabetically between
`./eza.nix` and `./fd.nix`. The module SHALL NOT write a
`xdg.configFile."fastfetch/config.jsonc"` entry by hand; the rendered
JSON SHALL come from home-manager's `settings`-to-JSON conversion.

#### Scenario: binary is on PATH after activation
- **WHEN** `nh os switch` completes on any active host (`lv426`,
  `demiurge`, `arrakis`, `nostromo`)
- **THEN** `which fastfetch` returns a `/nix/store/...-fastfetch-*/bin/fastfetch` path
- **AND** `fastfetch --version` reports a non-empty version string

#### Scenario: rendered config is produced by home-manager
- **WHEN** `nh os build` completes
- **THEN** the closure contains a `~/.config/fastfetch/config.jsonc`
  symlink pointing into the Nix store
- **AND** the store-path content is valid JSON parseable by
  `jq -c . < config.jsonc`
- **AND** there is no hand-authored JSONC file in
  `modules/home/programs/` (verified by `rg -F 'config.jsonc'
  modules/home/programs/fastfetch.nix` returning no match)

#### Scenario: missing home-manager fastfetch module fails closed
- **WHEN** the active `home-manager` revision does not provide
  `programs.fastfetch` (e.g. an unexpected downgrade)
- **THEN** `nh os build` fails with an `option 'programs.fastfetch'
  does not exist` error
- **AND** no half-written `~/.config/fastfetch/` is left on disk

### Requirement: cluster colors are stylix-derived

The module SHALL source every `keyColor` and the `display.color.separator`
field from `config.lib.stylix.colors.base*-rgb-{r,g,b}` decimal channel
attributes, rendered as ANSI 24-bit SGR parameter strings of the form
`"38;2;R;G;B"`. The module SHALL NOT hard-code hex literals or
RGB-decimal tuples for the cluster colors. The cluster → base16 mapping
SHALL be:

- Title key: `base05`
- Hardware: `base08`
- Firmware: `base09`
- Software: `base0F`
- Theme: `base0E`
- Network: `base0D`
- Separator: `base03`
- Logo color 1: `base0D`

#### Scenario: theme switch propagates without module edit
- **WHEN** the user changes the active stylix base16 scheme (e.g. via
  `values.theme.base16Scheme` in `hosts/default.nix`)
- **THEN** `nh os switch` re-renders `config.jsonc` with the new
  scheme's RGB channels in every cluster's `keyColor`
- **AND** `modules/home/programs/fastfetch.nix` requires no edits

#### Scenario: SGR strings are well-formed
- **WHEN** the rendered `config.jsonc` is inspected
- **THEN** every `keyColor` matches the regex `^38;2;\d{1,3};\d{1,3};\d{1,3}$`
- **AND** every channel value is in `0..255`

#### Scenario: missing stylix attribute fails the build
- **WHEN** the helper `sgr` references a non-existent base16 attribute
  (e.g. typo `base0Z`)
- **THEN** `nh os build` fails with an `attribute … missing` error from
  `config.lib.stylix.colors`
- **AND** the failure cites the offending lookup path

### Requirement: module list matches dede's cluster layout

The rendered `settings.modules` SHALL be ordered exactly as
title → break → Hardware cluster → break → Firmware cluster → break →
Software cluster → break → Theme cluster → break → Network cluster →
break → `colors`. Each cluster SHALL open with a `{ type = "custom";
format = "{#1;<sgr>}<icon> <ClusterName>{#}"; }` header line using the
cluster's stylix-derived SGR. Inside each cluster, every module SHALL
carry a `key` field with a tree-drawing prefix (`├` for non-final, `└`
for final) and a `keyColor` equal to the cluster SGR. The `display`
section SHALL set `separator = " ~> "` and `color.separator` to the
separator SGR.

#### Scenario: cluster order is preserved
- **WHEN** the rendered JSON is parsed
- **THEN** `.modules | map(select(.type == "custom")) | map(.format)`
  returns the cluster headers in the order Hardware, Firmware, Software,
  Theme, Network

#### Scenario: every cluster has exactly one `└` terminator
- **WHEN** the rendered JSON is parsed and modules are grouped by their
  preceding `"break"` boundaries
- **THEN** each cluster group contains exactly one module whose `key`
  starts with `└`
- **AND** all other modules in the cluster start with `├`

#### Scenario: malformed cluster (no terminator) is rejected
- **WHEN** an editor mistakenly removes the `└` line from any cluster
- **THEN** `nix flake check` does not catch it (this is a content-level
  invariant, not a type error), but the human-verification checkpoint
  in `tasks.md` SHALL spot the missing terminator
- **AND** the contributor reverts before `nh os switch`

### Requirement: art files ship in-repo and resolve by hostname

The module SHALL ship seven ASCII art files under
`modules/home/programs/fastfetch/art/`:
`rosh.txt`, `rosh-color.txt`, `nix.txt`, `mgs.txt`, `vagabond.txt`,
`varre.txt`, and `laurel.txt`. The first six SHALL be byte-identical to
their counterparts in `aef318858^:modules/home/configurations/macchina/themes/`
(renamed from `.ascii` to `.txt`). `laurel.txt` SHALL contain the bytes
of `dededecline/dotfiles/fastfetch/logo_hera.txt` with a single leading
`#` comment line attributing the source. All seven SHALL be deployed to
`${xdg.configHome}/fastfetch/art/` via `xdg.configFile`. The active art
SHALL be materialized at `${xdg.configHome}/fastfetch/logo.txt` (a
symlink or `xdg.configFile.source = ./art/<chosen>.txt`), and the
`programs.fastfetch.settings.logo.source` SHALL point at that single
stable path.

Hostname → default art mapping:

- `lv426` → `rosh`
- `demiurge` → `laurel`
- `arrakis` → `nix`
- `nostromo` → `nix`
- any other hostname → `rosh`

The mapping SHALL live in `modules/home/programs/fastfetch.nix` as a
plain attrset; adding a host requires editing this attrset.

#### Scenario: per-host art resolves correctly
- **WHEN** `nh os switch` completes on `lv426`
- **THEN** `~/.config/fastfetch/logo.txt` resolves (via symlink chain)
  to the contents of `rosh.txt`
- **AND** running `fastfetch` displays the rosh art

#### Scenario: demiurge gets the laurel art
- **WHEN** `nh os switch` completes on `demiurge`
- **THEN** `~/.config/fastfetch/logo.txt` resolves to the contents of
  `laurel.txt`
- **AND** `head -1 ~/.config/fastfetch/logo.txt` returns the attribution
  comment line
- **AND** `fastfetch` renders the hera/laurel logo with `base0D`-tinted
  color

#### Scenario: all seven art files are available for manual switching
- **WHEN** the user inspects `~/.config/fastfetch/art/`
- **THEN** the directory contains all of `rosh.txt`, `rosh-color.txt`,
  `nix.txt`, `mgs.txt`, `vagabond.txt`, `varre.txt`, `laurel.txt`
- **AND** the user can manually rebuild with a different mapping entry
  to switch the active art without editing fastfetch upstream

#### Scenario: unknown host falls back to rosh
- **WHEN** `nh os switch` runs on a host whose name is not in the four-
  entry map (e.g. a future `borealis` host)
- **THEN** `logo.txt` resolves to `rosh.txt`
- **AND** the build does not fail or warn — the fallback is intentional

#### Scenario: missing art file fails the build
- **WHEN** the hostname map references an art name (e.g. `"laurel"`)
  whose `art/<name>.txt` file is missing from the repo
- **THEN** `nh os build` fails with a `path does not exist` error citing
  the missing `.txt`
- **AND** no partial `~/.config/fastfetch/` is written

### Requirement: Software cluster is platform-conditional

The `Software` cluster's `Packages` module SHALL differ between Darwin
and NixOS hosts. On Darwin (`pkgs.stdenv.isDarwin`), the module SHALL
shell out to `printf '%s (brew), %s (brew-cask), %s (mas)' "$(ls -1
/opt/homebrew/Cellar 2>/dev/null | wc -l | tr -d ' ')" "$(ls -1
/opt/homebrew/Caskroom 2>/dev/null | wc -l | tr -d ' ')" "$(mas list
2>/dev/null | wc -l | tr -d ' ')"`. On Linux (`pkgs.stdenv.isLinux`),
the module SHALL shell out to `nix-store -q --requisites
/run/current-system | wc -l | tr -d ' '` and label the count as
`(nix-store)`. The `Theme` cluster's `OS` light/dark module SHALL be
included only on Darwin.

#### Scenario: Darwin renders brew-style package counts
- **WHEN** the user runs `fastfetch` on `lv426` or `demiurge`
- **THEN** the `Packages` line shows three integer counts followed by
  ` (brew), N (brew-cask), N (mas)`
- **AND** none of the counts are an error message or empty string

#### Scenario: NixOS renders nix-store count
- **WHEN** the user runs `fastfetch` on `arrakis`
- **THEN** the `Packages` line shows a single integer followed by
  ` (nix-store)`
- **AND** the integer is at least 100 (sanity floor — a working NixOS
  closure has thousands of paths)

#### Scenario: NixOS skips the macOS-only Theme/OS line
- **WHEN** the rendered `config.jsonc` is inspected on `arrakis`
- **THEN** no module reads `defaults read -g AppleInterfaceStyle`
- **AND** the `Theme` cluster still renders (with `Desktop` and `Font`
  rows), just without the OS-light-or-dark first row

#### Scenario: missing platform branch fails to evaluate
- **WHEN** a future hypothetical platform (neither `isDarwin` nor
  `isLinux`) tries to build the module
- **THEN** the module produces an empty Software cluster (graceful
  degradation), and `nh os build` succeeds without throwing
- **AND** `fastfetch` simply omits the cluster rather than failing

### Requirement: module is idempotent and does not touch user state

The module SHALL NOT write to any path under `~/` outside of
`~/.config/fastfetch/`. The module SHALL NOT auto-run `fastfetch` from
shell init, login hook, or activation script. The module SHALL NOT edit
`modules/home/programs/zsh/`, `modules/home/programs/nushell.nix`, or
any other shell module.

#### Scenario: zsh module is unchanged
- **WHEN** the change is applied
- **THEN** `git diff main -- modules/home/programs/zsh/` is empty
- **AND** `fastfetch` does not appear in any shell init script

#### Scenario: activation is a no-op for non-fastfetch paths
- **WHEN** the user inspects file changes after `nh os switch`
- **THEN** the only paths added or modified under `~/.config/` belong
  to `~/.config/fastfetch/`
- **AND** no `~/.local/share/fastfetch/` cache directory is pre-created

#### Scenario: re-running `nh os switch` is a no-op
- **WHEN** `nh os switch` is run twice with no source changes between
- **THEN** the second run reports zero changed paths
- **AND** `~/.config/fastfetch/` is unchanged between runs
