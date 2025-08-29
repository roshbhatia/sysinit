#!/usr/bin/env bash
# shellcheck disable=all
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logger.sh"

if [ "$EUID" -eq 0 ]; then
  log_error "Please do not run this script as root or with sudo."
  exit 1
fi

log_info "Installing Nix Package Manager"
if ! command -v nix &> /dev/null; then
  if [ -f "/nix/nix-installer" ] && [ -f "/nix/receipt.json" ]; then
    log_warn "Found Determinate Systems Nix installer but nix command not available."
    log_warn "Running nix-installer repair to fix the installation..."
    sudo /nix/nix-installer repair || {
      log_critical "Failed to repair Nix installation"
      exit 1
    }
  else
    log_warn "Installing Nix using Determinate Systems installer..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm || {
      log_critical "Failed to install Nix"
      exit 1
    }
  fi

  log_warn "Setting up Nix environment..."
  if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
  else
    log_critical "Failed to source Nix environment. Please restart your terminal and run this script again."
    exit 1
  fi
  log_success "Nix installed successfully"
else
  log_success "Nix already installed"
fi

log_info "Creating Per-user Profile"
if [ ! -d "$HOME/.nix-profile" ] || [ ! -L "$HOME/.nix-profile" ]; then
  log_warn "Setting up per-user profile for $(whoami)..."
  nix-env --install || {
    log_critical "Failed to create per-user profile"
    exit 1
  }
  log_success "Per-user profile created successfully"
else
  log_success "Per-user profile already exists"
fi

log_info "Enabling Nix Flakes and Setting Permissions"
mkdir -p ~/.config/nix
FLAKES_CONFIG="experimental-features = nix-command flakes"
TRUSTED_USERS="trusted-users = root $(whoami)"

sudo touch ~/.config/nix/nix.conf
sudo chmod 775 ~/.config/nix/nix.conf
if ! grep -q "$FLAKES_CONFIG" ~/.config/nix/nix.conf 2> /dev/null; then
  echo "$FLAKES_CONFIG" >> ~/.config/nix/nix.conf
  log_success "Nix Flakes enabled"
else
  log_success "Nix Flakes already enabled"
fi

if ! grep -q "trusted-users" ~/.config/nix/nix.conf 2> /dev/null; then
  echo "$TRUSTED_USERS" >> ~/.config/nix/nix.conf
  log_success "Trusted users configured"
else
  log_success "Trusted users already configured"
fi

log_info "Installing Nix-Darwin"
if ! command -v darwin-rebuild &> /dev/null; then
  log_warn "Installing Nix-Darwin..."

  mkdir -p ~/.nixpkgs
  if [ ! -f ~/.nixpkgs/darwin-configuration.nix ]; then
    log_warn "Linking minimal darwin configuration..."
    sudo ln -sf "$SCRIPT_DIR/configs/darwin-configuration.nix" ~/.nixpkgs/darwin-configuration.nix
    log_success "Darwin configuration linked"
  fi

  if [ -f "/opt/homebrew/opt/libgit2/lib/libgit2.1.9.0.dylib" ] && [ ! -f "/opt/homebrew/opt/libgit2/lib/libgit2.1.8.dylib" ]; then
    log_warn "Creating libgit2 compatibility symlink..."
    sudo ln -s /opt/homebrew/opt/libgit2/lib/libgit2.1.9.0.dylib /opt/homebrew/opt/libgit2/lib/libgit2.1.8.dylib
    log_success "libgit2 symlink created"
  elif [ -f "/opt/homebrew/opt/libgit2/lib/libgit2.1.8.dylib" ]; then
    log_success "libgit2 compatibility symlink already exists"
  fi

  mkdir -p /tmp/nix-darwin-bootstrap
  sudo ln -sf "$SCRIPT_DIR/configs/bootstrap-flake.nix" /tmp/nix-darwin-bootstrap/flake.nix
  log_success "Bootstrap flake configuration linked"

  log_warn "Building and activating bootstrap configuration..."
  cd /tmp/nix-darwin-bootstrap || {
    log_critical "Failed to change to bootstrap directory"
    exit 1
  }

  nix build --extra-experimental-features "nix-command flakes" .#darwinConfigurations.bootstrap.system

  if ! command -v darwin-rebuild &> /dev/null; then
    log_warn "Creating temporary darwin-rebuild command..."
    sudo mkdir -p /usr/local/bin
    sudo ln -sf "$SCRIPT_DIR/configs/darwin-rebuild-script" /usr/local/bin/darwin-rebuild
    sudo chmod +x /usr/local/bin/darwin-rebuild
    log_success "Darwin rebuild command linked"
  fi

  export NIXPKGS_ALLOW_INSECURE=1

  log_warn "Activating nix-darwin with force flag..."
  ./result/activate-user || true
  sudo ./result/activate || {
    log_critical "Failed to bootstrap nix-darwin"
    exit 1
  }

  cd - > /dev/null || {
    log_critical "Failed to change back to original directory"
    exit 1
  }
  rm -rf /tmp/nix-darwin-bootstrap

  log_success "Nix-Darwin installed successfully"
  log_warn "You may need to restart your terminal or run 'exec $SHELL' to access darwin-rebuild"
else
  log_success "Nix-Darwin already installed"
fi
