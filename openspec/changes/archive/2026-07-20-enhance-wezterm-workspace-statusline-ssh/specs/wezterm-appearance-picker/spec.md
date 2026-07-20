## ADDED Requirements

### Requirement: Appearance picker is reachable from a single dispatcher key

A `SUPER+SHIFT+l` binding SHALL open one `InputSelector` listing the lantern
appearance categories (colorscheme, font, font size, font leading, font
ligatures, GPU / front end, window opacity, window padding, inactive-pane
opacity, cursor style, tab-bar style). Selecting a category SHALL perform that
category's own lantern wick selector (`lantern.light.<category>()`). The binding
SHALL NOT use lantern's upstream `CTRL+SHIFT+c/f/…` defaults, which collide with
this config's copy (`CTRL+SHIFT+c`) and pane-select (`CTRL+SHIFT+f`).

#### Scenario: Dispatcher opens and chains to a wick

- **WHEN** the user presses `SUPER+SHIFT+l` and selects "Colorscheme"
- **THEN** lantern's colorscheme selector opens and choosing a scheme applies it
  live

#### Scenario: Locked mode passes the key through (negative)

- **WHEN** the terminal is in locked mode and the user presses `SUPER+SHIFT+l`
- **THEN** the key is sent to the pane rather than opening the dispatcher,
  matching the other smart keybindings' locked-mode passthrough

#### Scenario: Plugin load failure leaves the binding unregistered (negative)

- **WHEN** `lantern.wz` fails to load
- **THEN** the failure is logged and the `SUPER+SHIFT+l` binding is simply not
  registered, rather than the config erroring at startup

### Requirement: lantern resolves its bundled flames from the Nix store

Before loading lantern, the config SHALL set
`wezterm.GLOBAL.__lantern_plugin_dir` to lantern's Nix store path (from
`config.json`'s `plugins.lantern`), because lantern's `meta` locates its bundled
flame choice-sets either from a plugin url containing `lantern.wz` or from that
global — and the Nix store path (`/nix/store/HASH-source`) contains neither. The
config SHALL also call `lantern.rekindle(config)` so a previously-picked
appearance is restored on startup.

#### Scenario: Built-in wicks have choices

- **WHEN** lantern is loaded with `wezterm.GLOBAL.__lantern_plugin_dir` set
- **THEN** the colorscheme / font / GPU wicks register with their bundled choices
  rather than empty selectors

#### Scenario: lantern deps resolve through the plugin loader

- **WHEN** lantern's patched `deps.lua` requests `log`/`memo`/`ribbon`/`warp`
- **THEN** they resolve through `plugin_loader.load` (the Nix-store path) instead
  of `wezterm.plugin.require`, which cannot git-clone from the store
