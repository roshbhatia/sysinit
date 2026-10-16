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

## Releases

Successful checks on `main` run [semantic-release](https://github.com/semantic-release/semantic-release).
It creates `vMAJOR.MINOR.PATCH` tags and GitHub Releases with generated notes.
Breaking changes increment the major version. Features increment the minor version.
Fixes, performance changes, refactors, builds, chores, and reverts increment the patch version.
Documentation and test changes appear in the next release's notes.

[CHANGELOG.md](CHANGELOG.md) archives reconstructed history through `v3.112.4`.
Those versions describe commit messages; they do not prove historical deployment or testing.
Later release notes live in [GitHub Releases](https://github.com/roshbhatia/sysinit/releases).

The reconstruction uses the same analyzer and notes generator as future releases.
It groups merged changes at their mainline merge and preserves existing tags.
Unclassified messages appear in notes but do not independently cause releases.

```sh
nix develop .#release --command node --test checks/releases.mjs
nix develop .#release --command node hack/reconstruct-releases.mjs af6633e808586412530da091a0dc327d62a52382 .sysinit/historical-releases
```
