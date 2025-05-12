#!/usr/bin/env bash
# shellcheck disable=all
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logger.sh"

if [ "$EUID" -eq 0 ]; then
    log_error "Please do not run this script as root or with sudo."
    exit 1
fi

log_info "Step 1: Installing Nix Package Manager"
if ! command -v nix &>/dev/null; then
    if [ -f "/nix/nix-installer" ] && [ -f "/nix/receipt.json" ]; then
        log_warn "Found Determinate Systems Nix installer but nix command not available."
        log_warn "Running nix-installer repair to fix the installation..."
        sudo /nix/nix-installer repair || log_critical "Failed to repair Nix installation" && exit 1
    else
        log_warn "Installing Nix using Determinate Systems installer..."
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm || log_critical "Failed to install Nix" && exit 1
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

log_info "Step 2: Creating Per-user Profile"
if [ ! -d "$HOME/.nix-profile" ] || [ ! -L "$HOME/.nix-profile" ]; then
    log_warn "Setting up per-user profile for $(whoami)..."
    nix-env --install --attr nixpkgs.nix || log_critical "Failed to create per-user profile" && exit 1
    log_success "Per-user profile created successfully"
else
    log_success "Per-user profile already exists"
fi

log_info "Step 3: Enabling Nix Flakes and Setting Permissions"
mkdir -p ~/.config/nix
FLAKES_CONFIG="experimental-features = nix-command flakes"
TRUSTED_USERS="trusted-users = root $(whoami)"

sudo touch ~/.config/nix/nix.conf
sudo chmod 775 ~/.config/nix/nix.conf
if ! grep -q "$FLAKES_CONFIG" ~/.config/nix/nix.conf 2>/dev/null; then
    echo "$FLAKES_CONFIG" >> ~/.config/nix/nix.conf
    log_success "Nix Flakes enabled"
else
    log_success "Nix Flakes already enabled"
fi

if ! grep -q "trusted-users" ~/.config/nix/nix.conf 2>/dev/null; then
    echo "$TRUSTED_USERS" >> ~/.config/nix/nix.conf
    log_success "Trusted users configured"
else
    log_success "Trusted users already configured"
fi

log_info "Step 4: Preparing System Files"
FILES_TO_BACKUP=(
    "/etc/bashrc"
    "/etc/zshrc"
    "/etc/ssl/certs/ca-certificates.crt"
)

for file in "${FILES_TO_BACKUP[@]}"; do
    if [[ -f "$file" && ! -f "${file}.before-nix-darwin" ]]; then
        log_warn "Moving $file to ${file}.before-nix-darwin"
        sudo mv "$file" "${file}.before-nix-darwin" || log_warn "Warning: Could not move $file"
        log_success "Backed up $file"
    elif [[ -f "$file" ]]; then
        log_warn "File $file exists but already has a backup. Renaming it anyway."
        sudo mv "$file" "${file}.before-nix-darwin-$(date +%Y%m%d%H%M%S)" || log_warn "Warning: Could not move $file"
        log_success "Backed up $file with timestamp"
    else
        log_success "$file already prepared or doesn't exist"
    fi
done

log_info "Step 5: Installing Nix-Darwin"
if ! command -v darwin-rebuild &>/dev/null; then
    log_warn "Installing Nix-Darwin..."
    
    mkdir -p ~/.nixpkgs
    if [ ! -f ~/.nixpkgs/darwin-configuration.nix ]; then
        log_warn "Creating minimal darwin configuration..."
        cat > ~/.nixpkgs/darwin-configuration.nix << EOF
{ pkgs, ... }:
{
  system.configurationRevision = null;
  system.stateVersion = 4;
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  nix.enable = false;
  
  nix.settings = {
    trusted-users = [ "root" "$(whoami)" ];
    experimental-features = [ "nix-command" "flakes" ];
  };

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    git
    curl
    libgit2
  ];
  
  security.pam.services.sudo_local.touchIdAuth = true;
}
EOF
    fi
    
    if [ -f "/opt/homebrew/opt/libgit2/lib/libgit2.1.9.0.dylib" ] && [ ! -f "/opt/homebrew/opt/libgit2/lib/libgit2.1.8.dylib" ]; then
        log_warn "Creating libgit2 compatibility symlink..."
        sudo ln -s /opt/homebrew/opt/libgit2/lib/libgit2.1.9.0.dylib /opt/homebrew/opt/libgit2/lib/libgit2.1.8.dylib
        log_success "libgit2 symlink created"
    elif [ -f "/opt/homebrew/opt/libgit2/lib/libgit2.1.8.dylib" ]; then
        log_success "libgit2 compatibility symlink already exists"
    fi
    
    mkdir -p /tmp/nix-darwin-bootstrap
    cat > /tmp/nix-darwin-bootstrap/flake.nix << 'EOF'
{
  description = "Bootstrap configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, darwin, nixpkgs }: {
    darwinConfigurations.bootstrap = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        {
          system.stateVersion = 4;
          nix.enable = false;
          programs.zsh.enable = true;
          system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
          system.defaults.finder.AppleShowAllExtensions = true;
        }
      ];
    };
  };
}
EOF

    log_warn "Building and activating bootstrap configuration..."
    cd /tmp/nix-darwin-bootstrap || exit || exit || exit || exit || exit
    
    nix build --extra-experimental-features "nix-command flakes" .#darwinConfigurations.bootstrap.system
    
    if ! command -v darwin-rebuild &>/dev/null; then
        log_warn "Creating temporary darwin-rebuild command..."
        sudo mkdir -p /usr/local/bin
        cat > /tmp/darwin-rebuild << 'SCRIPT'
#!/bin/sh
exec /nix/var/nix/profiles/default/bin/nix run --extra-experimental-features "nix-command flakes" \
    github:lnl7/nix-darwin \
    -- "$@"
SCRIPT
        sudo mv /tmp/darwin-rebuild /usr/local/bin/
        sudo chmod +x /usr/local/bin/darwin-rebuild
    fi
    
    export NIXPKGS_ALLOW_INSECURE=1
    
    log_warn "Activating nix-darwin with force flag..."
    ./result/activate-user || true
    sudo ./result/activate || log_critical "Failed to bootstrap nix-darwin" && exit 1
    
    cd - >/dev/null || exit || exit || exit || exit || exit
    rm -rf /tmp/nix-darwin-bootstrap
    
    log_success "Nix-Darwin installed successfully"
    log_warn "You may need to restart your terminal or run 'exec $SHELL' to access darwin-rebuild"
else
    log_success "Nix-Darwin already installed"
fi
