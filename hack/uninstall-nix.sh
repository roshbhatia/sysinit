#!/usr/bin/env bash
set -e
# shellcheck disable=all
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

function handle_error {
    echo -e "${RED}Error: $1${NC}"
    echo "Uninstallation failed. Please check the error message above."
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

log_info "============================================================"
log_info "              Nix Complete Uninstaller                       "
log_info "============================================================"
echo ""
log_warning "WARNING: This script will completely remove Nix, nix-darwin, and all related configuration from your system."
log_warning "This is a destructive operation and cannot be undone!"
echo ""
read -p "Are you sure you want to continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Uninstallation cancelled."
    exit 0
 fi

log_info "Step 1: Stopping Nix services..."
# Stop nix-daemon service if running
if sudo launchctl list | grep -q org.nixos.nix-daemon; then
    log_warning "Stopping nix-daemon service..."
    sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
    log_success "nix-daemon service stopped"
fi

# Stop other potential Nix services
for service in org.nixos.activate-system org.nixos.darwin-store; do
    if sudo launchctl list | grep -q $service; then
        log_warning "Stopping $service service..."
        sudo launchctl unload /Library/LaunchDaemons/$service.plist 2>/dev/null || true
        log_success "$service service stopped"
    fi
done

# Make sure no processes are accessing Nix store files
log_warning "Checking for processes using Nix store..."
if pgrep -f "/nix" > /dev/null; then
    log_warning "Found processes using Nix store, attempting to terminate..."
    sudo pkill -f "/nix" || true
    sleep 2
fi

log_info "Step 2: Removing configuration files..."

# Remove Nix configuration files
if [ -d /etc/nix ]; then
    log_warning "Removing /etc/nix..."
    sudo rm -rf /etc/nix
    log_success "Removed /etc/nix"
fi

# Remove user-specific Nix configuration
if [ -d ~/.config/nix ]; then
    log_warning "Removing ~/.config/nix..."
    sudo rm -rf ~/.config/nix
    log_success "Removed ~/.config/nix"
fi

# Remove nix-darwin related configurations
for file in "/etc/bashrc" "/etc/zshrc" "/etc/bash.bashrc" "/etc/zsh/zshrc"; do
    if [ -f "${file}.before-nix-darwin" ]; then
        log_warning "Restoring original ${file}..."
        sudo mv "${file}.before-nix-darwin" "${file}" || true
        log_success "Restored ${file}"
    elif [ -L "${file}" ]; then
        log_warning "Removing symlinked ${file}..."
        sudo rm -f "${file}" || true
        log_success "Removed ${file}"
    fi
done

# Remove nix-darwin profiles
if [ -d ~/.nix-defexpr ]; then
    log_warning "Removing ~/.nix-defexpr..."
    sudo rm -rf ~/.nix-defexpr
    log_success "Removed ~/.nix-defexpr"
fi

if [ -L ~/.nix-profile ]; then
    log_warning "Removing ~/.nix-profile..."
    sudo rm -f ~/.nix-profile
    log_success "Removed ~/.nix-profile"
fi

# Remove nix-darwin state folders
if [ -d ~/.local/state/nix ]; then
    log_warning "Removing ~/.local/state/nix..."
    sudo rm -rf ~/.local/state/nix
    log_success "Removed ~/.local/state/nix"
fi

log_info "Step 3: Removing launch daemons..."
# Remove launch daemons
for plist in /Library/LaunchDaemons/org.nixos.*.plist; do
    if [ -f "$plist" ]; then
        log_warning "Removing $plist..."
        sudo rm -f "$plist"
        log_success "Removed $plist"
    fi
done

log_info "Step 4: Removing Nix store and related files..."
# Remove Nix store and related directories
for dir in /nix /var/root/.nix-profile /var/root/.nix-defexpr /var/root/.nix-channels; do
    if [ -e "$dir" ]; then
        log_warning "Removing $dir..."
        # Handle .Trashes directory with special permissions
        if [ "$dir" = "/nix" ] && [ -d "/nix/.Trashes" ]; then
            log_warning "Removing /nix/.Trashes directory with special permissions..."
            sudo rm -rf /nix/.Trashes 2>/dev/null || true
        fi
        sudo rm -rf "$dir" || log_warning "Warning: Could not fully remove $dir, continuing anyway"
        if [ ! -e "$dir" ]; then
            log_success "Removed $dir"
        else
            log_warning "Partial removal of $dir, some files may remain"
        fi
    fi
done

# Remove darwin system link if it exists
if [ -L /run/current-system ]; then
    log_warning "Removing /run/current-system symlink..."
    sudo rm -f /run/current-system
    log_success "Removed /run/current-system symlink"
fi

# Remove backup files created by nix-darwin
log_info "Step 5: Cleaning up backup files..."

# Remove system backup files
log_warning "Removing system backup files..."
sudo rm -f /etc/*.before-nix-darwin || true
log_success "Removed system backup files"

# Remove home directory backup files
log_warning "Removing home directory backup files..."
sudo rm -f "$HOME/.*.backup""*"" """"$HO"M"E"/.*.bak || true
log_success "Removed home directory backup files"

# Remove XDG config backup files
log_warning "Removing XDG config backup files..."
find "$HOME"/.config -name "*.backup" -o -name "*.bak" -exec sudo rm -f {} \; || true
log_success "Removed XDG config backup files"

# Clean up /etc entries that might have been created
if [ -d /etc/static ]; then
    log_warning "Removing /etc/static..."
    sudo rm -rf /etc/static
    log_success "Removed /etc/static"
fi

# Remove any lines referencing Nix from shell rc files
log_info "Step 6: Cleaning up shell configuration files..."
for file in "$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [ -f "$file" ]; then
        log_warning "Removing Nix references from $file..."
        sed -i.bak '/nix/d' "$file" || true
        sudo rm -f "${file}.bak" || true
        log_success "Cleaned up $file"
    fi
done

log_info "Step 7: Removing Nix users and groups..."
# Remove Nix-related users and groups
if dscl . -list /Groups | grep -q nixbld; then
    for i in $(seq 1 32); do
        nixbld="nixbld${i}"
        if dscl . -list /Users | grep -q "$nixbld"; then
            log_warning "Removing user $nixbld..."
            sudo dscl . -delete /Users/"$nixbld" || true
            log_success "Removed user $nixbld"
        fi
    done
    log_warning "Removing group nixbld..."
    sudo dscl . -delete /Groups/nixbld || true
    log_success "Removed group nixbld"
fi

echo ""
log_info "============================================================"
log_info "              Uninstallation Complete!                       "
log_info "============================================================"
log_warning "You may need to restart your terminal or reboot your system for all changes to take effect."
echo ""
log_warning "To complete the cleanup process, you may want to:"
log_warning "  1. Restart your terminal sessions"
log_warning "  2. Remove any Nix-related environment variables"
log_warning "  3. Remove any Nix-related entries from your shell configuration files"
echo ""
