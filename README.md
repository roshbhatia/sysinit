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
# Build the system configuration
nix build .#darwinConfigurations.default.system

# Switch to the new configuration
./result/sw/bin/darwin-rebuild switch --flake .#default
```

## Updating

To update the system after making changes:

```bash
# Rebuild and switch to the new configuration
nix build .#darwinConfigurations.default.system
./result/sw/bin/darwin-rebuild switch --flake .#default
```
