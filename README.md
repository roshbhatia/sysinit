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
### Creating a Discrete Host Repository

To create a separate repository that consumes this flake for host-specific configurations (i.e., work machine):

```bash
nix flake init -t github:roshbhatia/sysinit#discrete
```

