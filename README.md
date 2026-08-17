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
# First run needs the nix run, then can be ommited
nix run nixpkgs#nh -- darwin switch .
nh -- darwin switch .
```
### Profiles

Every host picks one profile in `hosts/default.nix`. The three are additive, so
a package is listed once at the lowest profile that needs it.

| Profile | For | Holds |
| --- | --- | --- |
| `minimal` | a box you reach over ssh | a shell, a pager, an editor, git |
| `dev` | a box you build on | the above plus toolchains and the agent runtime |
| `workstation` | a box you sit in front of | the above plus the GUI |

### Installing on a Box With No Nix

`bootstrap/bootstrap.sh` brings the configuration up without Nix. It
sparse-clones this repository into `~/.local/share/sysinit` and installs the
tools through mise. It symlinks the neovim config, and writes a `.zshrc` that
sources the shell fragments.

```bash
curl -fsSL https://raw.githubusercontent.com/roshbhatia/sysinit/main/bootstrap/bootstrap.sh | bash
```

Pass `--editor` for the editor alone.
```bash
curl -fsSL https://raw.githubusercontent.com/roshbhatia/sysinit/main/bootstrap/bootstrap.sh | bash -s -- --editor
```

Both modes are re-runnable and both honor `SYSINIT_REMOTE`, `SYSINIT_BRANCH`, and
`SYSINIT_CHECKOUT`. `bootstrap/verify-container.sh` runs both in a clean Ubuntu
container.

### Creating a Discrete Host Repository

To create a separate repository that consumes this flake for host-specific configurations (i.e., work machine):

```bash
nix flake init -t github:roshbhatia/sysinit#discrete
```

