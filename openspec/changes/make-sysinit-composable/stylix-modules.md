# Every module that references stylix

Task 7.1's enumeration. 21 files, not 20: the task's count was one short.

What matters here is not the count but the split, and both halves break on a box
with no stylix module. Reading a COLOR breaks because `config.lib.stylix.colors`
does not exist there. Setting a TARGET breaks too, on the option name rather than
the value: stylix injects its home modules only when it is enabled, so with the
flag false `stylix.targets.<name>` is undeclared and a definition attached to an
undeclared option is an error, not a no-op. The two halves therefore need
different fixes, which is the real reason to split them.

## Reads colors, so needs a guard

These are what 7.2 guards. Each dereferences `config.lib.stylix.colors`, which
is an evaluation error when the stylix module is absent.

| File | What it sets | Already conditional |
|---|---|---|
| `darwin/borders.nix` | `JankyBorders` service arguments | no |
| `darwin/home/sketchybar/default.nix` | the bar's lua color table | no |
| `home/programs/fastfetch.nix` | the fastfetch JSON config | no |
| `home/programs/firefox.nix` | userChrome CSS and a tridactyl theme | no |
| `home/programs/fzf.nix` | `--color` flags | yes, on `config.stylix.enable` |
| `home/programs/hunk.nix` | a custom hunk theme | yes, on `config.stylix.enable` |
| `home/programs/llm/harnesses/pi/default.nix` | a pi theme JSON | no |
| `home/programs/omp.nix` | oh-my-posh segment colors | no |
| `home/programs/wezterm/default.nix` | the terminal color scheme | no |
| `home/programs/zoxide.nix` | `--color` flags on its fzf | yes, on `config.stylix.enable` |
| `home/programs/zsh/default.nix` | two `ZVM_VI_HIGHLIGHT_*` variables | no |
| `nixos/desktop/greetd.nix` | the tuigreet theme string | no |
| `nixos/home/desktop.nix` | waybar and the desktop's CSS | no |

Three already read `config.stylix.enable or false`. That idiom is this
repository's own and 7.2 extends it rather than replacing it, through
`themeLib.enabled`, which also reads `sysinit.theme.enable`.

Guarding these in place works because a guard here chooses a VALUE. The palette
comes from `themeLib.colorsOf config`, which returns stylix's colors when the
module is there and a written-down base16 default dark when it is not, so the
dereference never happens on a box without stylix.

The fallback has to match stylix's KEY SHAPE, not just carry sixteen colors. A
first version held only `base00` through `base0F` and 7.4 failed twice on it:
`fastfetch.nix` reads `base05-rgb-r` and the two other channels to build an SGR
escape, and it reads `scheme` to print the palette's name. Both are now derived
or written down. Only the plain name and the three `-rgb-*` channels are
produced, because that is what this repository reads. A consumer that starts
reading `-hex-r` or `withHashtag` gets a missing-attribute error naming the key.

## Sets a target, so it moved out of its module

Each was a single line toggling a stylix target. None consumes a color, so an
earlier draft recorded that none needed anything. That was wrong: the option
itself is gone when stylix is off, so all six failed.

They cannot be guarded in place. `lib.mkIf` makes a value conditional, not an
option name, and the definition is still attached to an option that is not
declared. Asking `config ? stylix` at module level forces the option set while
the option set is still being assembled, which is infinite recursion, observed
rather than reasoned about.

So all six moved into `modules/home/stylix-targets.nix`, which
`home/programs/default.nix` imports only when the `theme` argument is true. That
is the shape phase 6 used for profiles, and for the same reason: `imports` is
resolved before `config` exists.

| File it left | Line |
|---|---|
| `home/programs/helix.nix` | `stylix.targets.helix.opacity.enable = false` |
| `home/programs/neovim/default.nix` | `stylix.targets.neovim.enable = false` |
| `home/programs/vivid.nix` | `stylix.targets.vivid.enable = true` |
| `home/programs/firefox.nix` | also `stylix.targets.firefox.enable = false` |
| `home/programs/wezterm/default.nix` | also `stylix.targets.wezterm.enable = false` |
| `nixos/home/desktop.nix` | also `stylix.targets.waybar.addCss = false` |

The trade is that a target override no longer sits next to the program it
overrides. Grepping `stylix.targets` now finds one file rather than six.

An earlier draft got the color split wrong in both directions too. It listed
`helix.nix` and `vivid.nix` as generating theme files, which they do not, and it
missed `zoxide.nix` and the pi harness, which both read colors.

## Owns the stylix configuration itself

| File | Role |
|---|---|
| `darwin/stylix.nix` | sets `stylix.enable` and the scheme, fonts, and opacity for darwin |
| `nixos/common/stylix.nix` | the same for nixos |
| `darwin/default.nix` | imports `./stylix.nix` |
| `nixos/common/default.nix` | imports `./stylix.nix` |
| `shared/options/theme.nix` | the `sysinit.theme` options these read |

## Produces no file

`borders.nix` and `zsh/default.nix` read colors but produce service arguments
and environment variables rather than files. They are guarded like the rest,
because reading a color is what breaks, but 7.3's file comparison does not reach
them.
