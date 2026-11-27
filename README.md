# sysinit

Nix-managed dotfiles for macOS on Apple Silicon, NixOS, and Nix-on-Droid.
This repository owns system configuration, Home Manager modules, package overlays,
and shared shell and agent tooling.

## Build and apply

Install Nix, clone this repository, and select a host from [hosts/](hosts/).
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

Arda uses a [separately pinned Nix-on-Droid flake](hosts/arda) inside the same
checkout. On the tablet, run `nix-on-droid switch --flake ./hosts/arda#arda`
from the repository root.

To build Arda from a Mac configured to use Arrakis, set `android_uid` and
`android_gid` from `id -u` and `id -g` inside the tablet's Nix-on-Droid shell.

```sh
nix build --impure --argstr source "git+file://$PWD?dir=hosts/arda" \
  --arg uid "$android_uid" --arg gid "$android_gid" \
  --expr '{ source, uid, gid }: ((builtins.getFlake source).lib.mkArda [
    { user = { inherit uid gid; }; }
  ]).activationPackage'
```

## Structure

| Path | Purpose |
| --- | --- |
| `flake.nix`, `flake/` | Dependency declarations and output assembly, including package exports, cache bundles, and development shells |
| `hosts/` | Host identities, profiles, and machine settings |
| `features/` | Reusable feature modules registered through flake-parts |
| `modules/darwin/` | macOS system and desktop configuration |
| `modules/nixos/` | NixOS system configuration |
| `modules/home/` | Home Manager profile composition and shared subsystems |
| `modules/shared/` | Shared options and command paths |
| `overlays/` | Custom packages and upstream patches |
| `pkgs/` | Local command implementations |
| `hack/` | Maintenance and validation commands |
| `checks/` | Behavior and configuration checks |

The `minimal`, `dev`, and `workstation` profiles add shell tools, development tools,
and desktop applications in that order.

Reusable capabilities and their supporting files live under `features/`.
`features/module-exports.nix` registers named module entry points. Hosts and
profiles choose the variants they need. Larger features such as Neovim, Firefox,
GitHub tooling, Taskwarrior, and mail own their configuration and supporting files.
Related small modules live together under shell, CLI, development, Kubernetes,
and telemetry. Arda composes the shared Git identity, OpenSSH client,
and interactive Nushell modules with a grayscale terminal palette. Workstation
profiles add their Git and SSH policy. NixOS and Darwin share the Tailscale
service module and select their own Stylix integration. Named Base16 schemes
come from the pinned Tinted Theming source. Arrakis selects the remote builder
role explicitly.

Seshy owns session configuration, Tether owns transport configuration, and
WezTerm owns terminal configuration. The review and workspace features supply
their own command packages. The flake's `perSystem` module supplies one package
set per platform to packages, checks, development shells, and host builders.

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
in a separate repository. Its `sysinit.lib.mkHostLib inputs` call supplies host
builders with the consuming flake's input overrides.
