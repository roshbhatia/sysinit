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
### Lima NixOS VM

```bash
# Start Lima VM
limactl start --name=$HOSTNAME lima.yaml

# Shell into the VM
limactl shell 

# First run needs the nix run, then can be ommited
nix run nixpkgs#nh os switch '.#nixosConfigurations.nostromo'
nh os switch '.#nixosConfigurations.nostromo'
```

CRITICAL: Do NOT run `nh os switch` from macOS to configure the Lima VM. You must run it from INSIDE the VM.

### Creating a Discrete Host Repository

To create a separate repository that consumes this flake for host-specific configurations (i.e., work machine):

```bash
nix flake init -t github:roshbhatia/sysinit#discrete
```

### Installing Neovim Configuration Only

```bash
curl -fsSL https://raw.githubusercontent.com/roshbhatia/sysinit/main/setup/neovim.sh | bash
```

