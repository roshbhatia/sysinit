# SysInit

A Nix flake-based system configuration for macOS, using nix-darwin and home-manager.

Assumes I'm running on Arm64

## Installation

### Prerequisites

- Xcode Command Line Tools (`xcode-select --install`)

### Manual Installation

1. Install Nix using the Determinate Systems installer:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

2. Enable Nix Flakes:

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

3. Install nix-darwin:

```bash
# Install nix-darwin bootstrap
nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
./result/bin/darwin-installer

# Reload shell environment
source /etc/static/zshrc
```

4. Clone this repository:

```bash
git clone https://github.com/roshbhatia/sysinit.git
cd sysinit
```

5. Build and activate the configuration:

```bash
# For personal machines (includes all apps):
nix build .#darwinConfigurations.default.system
./result/sw/bin/darwin-rebuild switch --flake .#default

# For work machines (excludes personal apps):
nix build .#darwinConfigurations.work.system
./result/sw/bin/darwin-rebuild switch --flake .#work
```

## Structure

```
.
├── flake.nix                # Main flake configuration
├── modules/                 # Configuration modules
│   ├── darwin/              # macOS-specific settings
│   │   ├── default.nix
│   │   ├── system.nix       # System settings
│   │   └── homebrew/        # Homebrew applications
│   │       ├── default.nix  # Main homebrew config
│   │       ├── global.nix   # Work-appropriate packages
│   │       └── personal.nix # Personal-only packages
│   └── home/                # Home Manager configuration
│       ├── default.nix
│       └── packages.nix     # User packages
└── pkg/                     # Program configurations
    ├── default.nix          # Main package import file
    ├── atuin/               # Atuin configuration
    ├── git/                 # Git configuration
    ├── k9s/                 # K9s configuration
    ├── macchina/            # Macchina configuration
    ├── nvim/                # Neovim configuration
    │   ├── default.nix
    │   └── config/          # Neovim lua config files
    ├── starship/            # Starship configuration
    ├── wezterm/             # WezTerm configuration
    └── zsh/                 # Zsh configuration
```

## Updating

To update the system after making changes:

```bash
# For personal machines:
nix build .#darwinConfigurations.default.system
./result/sw/bin/darwin-rebuild switch --flake .#default

# For work machines:
nix build .#darwinConfigurations.work.system
./result/sw/bin/darwin-rebuild switch --flake .#work
```
