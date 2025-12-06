#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source logging library
source "${SCRIPT_DIR}/../modules/home/configurations/utils/system/loglib.sh"

if [ "$EUID" -eq 0 ]; then
  log_error "Please do not run this script as root or with sudo."
  exit 1
fi

log_info "Bootstrapping Nix and nix-darwin"

# Install Determinate Nix if not present
if ! command -v nix &>/dev/null; then
  log_warn "Installing Nix using Determinate Systems installer..."
  curl -L https://install.determinate.systems/nix | sh -s -- install --no-confirm || {
    log_critical "Failed to install Nix"
    exit 1
  }
  log_success "Nix installed successfully"
else
  log_success "Nix already installed"
fi

# Source Nix environment
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

# Create per-user profile if needed
if [ ! -d "$HOME/.nix-profile" ] || [ ! -L "$HOME/.nix-profile" ]; then
  log_warn "Setting up per-user profile..."
  nix-env --install || log_warn "Could not create per-user profile (may already exist)"
fi

# Build and activate bootstrap configuration
log_warn "Building bootstrap configuration..."
nix build --extra-experimental-features "nix-command flakes" "git+file://${PROJECT_ROOT}#darwinConfigurations.bootstrap.system" || {
  log_critical "Failed to build bootstrap configuration"
  exit 1
}

log_warn "Activating bootstrap configuration..."
./result/activate-user || true
sudo ./result/activate || {
  log_critical "Failed to activate bootstrap configuration"
  exit 1
}

log_success "Bootstrap configuration applied"
log_info "Building full system configuration..."
nix build --extra-experimental-features "nix-command flakes" "git+file://${PROJECT_ROOT}#darwinConfigurations.lv426.system" || {
  log_critical "Failed to build system configuration"
  exit 1
}

log_warn "Applying full system configuration..."
./result/activate-user || true
sudo ./result/activate || {
  log_critical "Failed to apply system configuration"
  exit 1
}
