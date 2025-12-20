#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ "$EUID" -eq 0 ]; then
  echo "Please do not run this script as root or with sudo."
  exit 1
fi

echo "Bootstrapping Nix and nix-darwin"

# Install Determinate Nix if not present
if ! command -v nix &> /dev/null; then
  echo "Installing Nix using Determinate Systems installer..."
  curl -L https://install.determinate.systems/nix | sh -s -- install --no-confirm || {
    echo "Failed to install Nix"
    exit 1
  }
  echo "Nix installed successfully"
else
  echo "Nix already installed"
fi

# Source Nix environment
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

# Create per-user profile if needed
if [ ! -d "$HOME/.nix-profile" ] || [ ! -L "$HOME/.nix-profile" ]; then
  echo "Setting up per-user profile..."
  nix-env --install || echo "Could not create per-user profile (may already exist)"
fi

# Build and activate bootstrap configuration
echo "Building bootstrap configuration..."
nix build --extra-experimental-features "nix-command flakes" "git+file://${PROJECT_ROOT}#darwinConfigurations.bootstrap.system" || {
  echo "Failed to build bootstrap configuration"
  exit 1
}

echo "Activating bootstrap configuration..."
./result/activate-user || true
sudo ./result/activate || {
  echo "Failed to activate bootstrap configuration"
  exit 1
}

echo "Bootstrap configuration applied"
echo "Building full system configuration..."
nix build --extra-experimental-features "nix-command flakes" "git+file://${PROJECT_ROOT}#darwinConfigurations.lv426.system" || {
  echo "Failed to build system configuration"
  exit 1
}

echo "Applying full system configuration..."
./result/activate-user || true
sudo ./result/activate || {
  echo "Failed to apply system configuration"
  exit 1
}
