# sysinit

```ascii
          ▗▄▄▄       ▗▄▄▄▄    ▄▄▄▖
          ▜███▙       ▜███▙  ▟███▛
           ▜███▙       ▜███▙▟███▛
            ▜███▙       ▜██████▛
     ▟█████████████████▙ ▜████▛     ▟▙
    ▟███████████████████▙ ▜███▙    ▟██▙
           ▄▄▄▄▖           ▜███▙  ▟███▛
          ▟███▛             ▜██▛ ▟███▛
         ▟███▛               ▜▛ ▟███▛
▟███████████▛                  ▟██████████▙
▜██████████▛                  ▟███████████▛
      ▟███▛ ▟▙               ▟███▛
     ▟███▛ ▟██▙             ▟███▛
    ▟███▛  ▜███▙           ▝▀▀▀▀
    ▜██▛    ▜███▙ ▜██████████████████▛
     ▜▛     ▟████▙ ▜████████████████▛
           ▟██████▙       ▜███▙
          ▟███▛▜███▙       ▜███▙
         ▟███▛  ▜███▙       ▜███▙
         ▝▀▀▀    ▀▀▀▀▘       ▀▀▀▘
```

This comprises most of my dotfiles, managed (mostly) by `nix`.

## Quick Start

### Build and Apply Configuration

```bash
# The first run needs `nix run`.
nix run nixpkgs#nh -- darwin switch .
nh darwin switch .
```
### Profiles

Every host picks one profile in `hosts/default.nix`. The three are additive, so
a package is listed once at the lowest profile that needs it.

| Profile | For | Holds |
| --- | --- | --- |
| `minimal` | a box you reach over ssh | a shell, a pager, an editor, git |
| `dev` | a box you build on | the above plus toolchains and the agent runtime |
| `workstation` | a box you sit in front of | the above plus the GUI |

### Installing the Editor on a Box With No Nix

`bootstrap/bootstrap.sh` installs the neovim config alone. It sparse-clones
this repository into `~/.local/share/sysinit` and symlinks the config to
`~/.config/nvim`. It installs no tools, so neovim, git, and a C compiler have to
be on PATH already.

```bash
curl -fsSL https://raw.githubusercontent.com/roshbhatia/sysinit/main/bootstrap/bootstrap.sh | bash
```

It is re-runnable and honors `SYSINIT_REMOTE`, `SYSINIT_BRANCH`, and
`SYSINIT_CHECKOUT`.

### Creating a Discrete Host Repository

To create a separate repository that consumes this flake for host-specific configurations (i.e., work machine):

```bash
nix flake init -t github:roshbhatia/sysinit#discrete
```
