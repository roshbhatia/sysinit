#!/usr/bin/env bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

function handle_error {
    echo -e "${RED}Error: $1${NC}"
    echo "Installation failed. Please check the error message above."
    exit 1
}

function log_success {
    echo -e "${GREEN}✓ $1${NC}"
}

function log_info {
    echo -e "${BLUE}$1${NC}"
}

function log_warning {
    echo -e "${YELLOW}$1${NC}"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    handle_error "Please do not run this script as root or with sudo."
fi

# Check for existing Nix installation that might be broken
if [ -d "/nix" ] && ! command -v nix &>/dev/null; then
    log_warning "WARNING: Detected a potentially broken Nix installation."
    log_warning "The /nix directory exists but the nix command is not available."
    echo ""
    read -p "Would you like to run the uninstall script before continuing? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "./uninstall-nix.sh" ]; then
            log_info "Running uninstall script..."
            bash ./uninstall-nix.sh
        else
            log_warning "Uninstall script not found. Please run it manually first."
            exit 1
        fi
    fi
fi

# Print banner
log_info "============================================================"
log_info "              Sysinit Deps Installer                        "
log_info "============================================================"
echo ""
echo "This script will install the prerequisites needed for sysinit:"
echo "- Xcode Command Line Tools"
echo "- Nix package manager (via Determinate Systems installer)"
echo "- Nix-Darwin"
echo "- Nix Flakes (configuration)"
echo ""

log_info "Step 1: Installing Xcode Command Line Tools"
if ! xcode-select -p &>/dev/null; then
    log_warning "Installing Xcode Command Line Tools..."
    xcode-select --install || handle_error "Failed to install Xcode Command Line Tools"
    log_warning "Please wait for Xcode Command Line Tools to finish installing, then press any key to continue..."
    read -n 1
else
    log_success "Xcode Command Line Tools already installed"
fi

log_info "Step 2: Installing Nix Package Manager"
if ! command -v nix &>/dev/null; then
    # Check if Determinate Systems installer exists but nix command doesn't
    if [ -f "/nix/nix-installer" ] && [ -f "/nix/receipt.json" ]; then
        log_warning "Found Determinate Systems Nix installer but nix command not available."
        log_warning "Running nix-installer repair to fix the installation..."
        sudo /nix/nix-installer repair || handle_error "Failed to repair Nix installation"
    else
        log_warning "Installing Nix using Determinate Systems installer..."
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm || handle_error "Failed to install Nix"
    fi
    
    # Source nix
    log_warning "Setting up Nix environment..."
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    else
        handle_error "Failed to source Nix environment. Please restart your terminal and run this script again."
    fi
    log_success "Nix installed successfully"
else
    log_success "Nix already installed"
fi

log_info "Step 3: Enabling Nix Flakes and Setting Permissions"
mkdir -p ~/.config/nix
FLAKES_CONFIG="experimental-features = nix-command flakes"
TRUSTED_USERS="trusted-users = root $(whoami)"

# Add flakes configuration if not present
if ! grep -q "$FLAKES_CONFIG" ~/.config/nix/nix.conf 2>/dev/null; then
    echo "$FLAKES_CONFIG" >> ~/.config/nix/nix.conf
    log_success "Nix Flakes enabled"
else
    log_success "Nix Flakes already enabled"
fi

# Add trusted users if not present
if ! grep -q "trusted-users" ~/.config/nix/nix.conf 2>/dev/null; then
    echo "$TRUSTED_USERS" >> ~/.config/nix/nix.conf
    log_success "Trusted users configured"
else
    log_success "Trusted users already configured"
fi

log_info "Step 4: Preparing System Files"
# List of files that need to be backed up before nix-darwin installation
FILES_TO_BACKUP=(
    "/etc/bashrc"
    "/etc/zshrc"
    "/etc/ssl/certs/ca-certificates.crt"
)

for file in "${FILES_TO_BACKUP[@]}"; do
    if [[ -f "$file" && ! -f "${file}.before-nix-darwin" ]]; then
        log_warning "Moving $file to ${file}.before-nix-darwin"
        sudo mv "$file" "${file}.before-nix-darwin" || log_warning "Warning: Could not move $file"
        log_success "Backed up $file"
    elif [[ -f "$file" ]]; then
        log_warning "File $file exists but already has a backup. Renaming it anyway."
        sudo mv "$file" "${file}.before-nix-darwin-$(date +%Y%m%d%H%M%S)" || log_warning "Warning: Could not move $file"
        log_success "Backed up $file with timestamp"
    else
        log_success "$file already prepared or doesn't exist"
    fi
done

log_info "Step 5: Installing Nix-Darwin"
# Check if nix-darwin is installed
if ! command -v darwin-rebuild &>/dev/null; then
    log_warning "Installing Nix-Darwin..."
    log_warning "This will take a few minutes..."
    
    # Create a minimal configuration.nix if it doesn't exist
    mkdir -p ~/.nixpkgs
    if [ ! -f ~/.nixpkgs/darwin-configuration.nix ]; then
        log_warning "Creating minimal darwin configuration..."
        cat > ~/.nixpkgs/darwin-configuration.nix << EOF
{ pkgs, ... }:
{
  # Set Git commit hash for darwin-version.
  system.configurationRevision = null;

  # Used for backwards compatibility
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # IMPORTANT: Disable nix management for Determinate Nix compatibility
  nix.enable = false;
  
  # Fix for permission denied issues
  nix.settings = {
    trusted-users = [ "root" "$(whoami)" ];
    experimental-features = [ "nix-command" "flakes" ];
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;

  # Packages to install
  environment.systemPackages = with pkgs; [
    git
    curl
    libgit2  # Add libgit2 to system packages
  ];
  
  # Enable Touch ID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;
}
EOF
    fi
    
    # Use the nix command to create a bootstrap configuration
    log_warning "Installing nix-darwin using the nix command..."
    
    # Add libgit2 symlink if needed
    if [ -f "/opt/homebrew/opt/libgit2/lib/libgit2.1.9.0.dylib" ] && [ ! -f "/opt/homebrew/opt/libgit2/lib/libgit2.1.8.dylib" ]; then
        log_warning "Creating libgit2 compatibility symlink..."
        sudo ln -s /opt/homebrew/opt/libgit2/lib/libgit2.1.9.0.dylib /opt/homebrew/opt/libgit2/lib/libgit2.1.8.dylib
        log_success "libgit2 symlink created"
    elif [ -f "/opt/homebrew/opt/libgit2/lib/libgit2.1.8.dylib" ]; then
        log_success "libgit2 compatibility symlink already exists"
    fi
    
    # Get current username
    CURRENT_USER=$(whoami)
    
    # Create a simple flake.nix file for bootstrap configuration
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
          
          # Disable nix-darwin's Nix management as we're using Determinate Systems
          nix.enable = false;
          
          # Create /etc/zshrc that loads the nix-darwin environment
          programs.zsh.enable = true;
          
          # Basic macOS defaults
          system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
          system.defaults.finder.AppleShowAllExtensions = true;
        }
      ];
    };
  };
}
EOF

    log_warning "Building and activating bootstrap configuration..."
    cd /tmp/nix-darwin-bootstrap
    
    # Run the nix command to build and switch to bootstrap configuration
    nix build --extra-experimental-features "nix-command flakes" .#darwinConfigurations.bootstrap.system
    
    # Create a local stub for darwin-rebuild if it doesn't exist
    if ! command -v darwin-rebuild &>/dev/null; then
        log_warning "Creating temporary darwin-rebuild command..."
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
    
    # Set NIXPKGS_ALLOW_INSECURE=1 to bypass any potential SSL warnings
    export NIXPKGS_ALLOW_INSECURE=1
    
    # Activate with --force flag to override file existence checks
    log_warning "Activating nix-darwin with force flag..."
    ./result/activate-user || true
    sudo ./result/activate || handle_error "Failed to bootstrap nix-darwin"
    
    # Clean up
    cd - >/dev/null
    rm -rf /tmp/nix-darwin-bootstrap
    
    log_success "Nix-Darwin installed successfully"
    
    # Recommend restart
    log_warning "You may need to restart your terminal or run 'exec $SHELL' to access darwin-rebuild"
else
    log_success "Nix-Darwin already installed"
fi

echo ""
log_info "============================================================"
log_info "                Install Complete                            "
log_info "============================================================"
echo ""
log_warning "Next Steps:"
echo ""
echo "   Build and switch to the configuration:"
echo ""
echo "   # For personal machines (with all apps):"
echo "   darwin-rebuild switch --flake .#default"
echo ""
echo "   # For work machines (without personal apps):"
echo "   darwin-rebuild switch --flake .#work"
echo ""
echo "   # For minimal setup without Homebrew (if 'result' directory was deleted):"
echo "   SYSINIT_NO_HOMEBREW=1 darwin-rebuild switch --flake .#default"
echo ""

log_info "============================================================"
log_info "                Troubleshooting Guide                       "
log_info "============================================================"
echo ""
log_warning "If your configuration fails to build:"
echo ""
echo "   1. Check for validation errors in the output - they will show as ERROR:"
echo "      - Missing required configuration properties"
echo "      - Non-existent files referenced in the configuration"
echo "      - Syntax errors in your configuration files"
echo ""
echo "   2. Fix the specific issue and try again"
echo ""

log_warning "If you encounter errors during activation:"
echo ""
echo "   # If files fail to install correctly:"
echo "   - Check the file paths in your config.nix"
echo "   - Ensure all source files exist and are readable"
echo "   - Verify destination paths are writable"
echo ""
echo "   # If you encounter libgit2 version mismatch errors with eza or git tools:"
echo "   sudo ln -s /opt/homebrew/opt/libgit2/lib/libgit2.1.9.0.dylib /opt/homebrew/opt/libgit2/lib/libgit2.1.8.dylib"
echo ""
echo "   # If you have permission denied issues with Nix store, update your nix settings:"
echo "   echo 'trusted-users = root \$USER' >> ~/.config/nix/nix.conf"
echo ""

log_info "============================================================"
log_info "                Rollback Instructions                       "
log_info "============================================================"
echo ""
log_warning "If you need to roll back your changes:"
echo ""
echo "   # List available system generations:"
echo "   darwin-rebuild list"
echo ""
echo "   # Roll back to previous system generation:"
echo "   darwin-rebuild switch --rollback"
echo ""
echo "   # List available home-manager generations:"
echo "   home-manager generations"
echo ""
echo "   # Roll back to specific home-manager generation:"
echo "   home-manager switch --generation 123"
echo ""
echo "   # Restore individual file backups (created during activation):"
echo "   # Look for files with .backup-YYYYMMDD-HHMMSS extension"
echo "   find ~ -name \"*.backup-*\" | grep ssh"
echo "   cp ~/.ssh/config.backup-20230101-120000 ~/.ssh/config"
echo ""
echo "   # If you need to completely uninstall and start fresh:"
echo "   ./uninstall-nix.sh"
echo ""
