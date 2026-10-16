# sysinit

Nix-managed dotfiles for macOS on Apple Silicon and NixOS.
This repository owns system configuration, Home Manager modules, package overlays,
and shared shell and agent tooling.

## Build and apply

Install Nix, clone this repository, and select a host from [hosts/default.nix](hosts/default.nix).
Review the host settings before applying them to another machine.

```sh
nix develop
nh darwin build .#lv426
nh darwin switch .#lv426
```

For NixOS, use the configured Linux host:

```sh
nh os build .#arrakis
nh os switch .#arrakis
```

A build checks the configuration without activating it. A switch applies it.
Use the installed `nh` for routine builds and switches.

## Structure

| Path | Purpose |
| --- | --- |
| `hosts/` | Host identities, profiles, and machine settings |
| `modules/darwin/` | macOS system and desktop configuration |
| `modules/nixos/` | NixOS system configuration |
| `modules/home/` | Home Manager programs and user configuration |
| `modules/shared/` | Shared options and command paths |
| `overlays/` | Custom packages and upstream patches |
| `pkgs/` | Local command implementations |
| `hack/` | Maintenance and validation commands |
| `checks/` | Behavior and configuration checks |

The `minimal`, `dev`, and `workstation` profiles add shell tools, development tools,
and desktop applications in that order.

[sysinit.nvim](https://github.com/roshbhatia/sysinit.nvim) owns the editor configuration.
[sysinit.wezterm](https://github.com/roshbhatia/sysinit.wezterm) owns the terminal configuration.
This flake pins both repositories and supplies host settings.

## Validate changes

```sh
nix fmt -- --check
nix develop --command bash hack/lint.sh --all
nix flake check
```

[AGENTS.md](AGENTS.md) describes repository conventions and known failure modes.
Edit managed configuration in its Nix source.

## Create a separate host repository

```sh
nix flake init -t github:roshbhatia/sysinit#discrete
```

The [discrete template](templates/discrete) consumes this flake and keeps host settings
in a separate repository.
