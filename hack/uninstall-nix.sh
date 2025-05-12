#!/usr/bin/env zsh
# shellcheck disable=all
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger/lib.sh"

if [ "$EUID" -eq 0 ]; then
    log_error "Please do not run this script as root or with sudo."
    exit 1
fi

log_warn "WARNING: This script will completely remove Nix, nix-darwin, and all related configuration from your system."
log_warn "This is a destructive operation and cannot be undone!"

read -p "Are you sure you want to continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Uninstallation cancelled."
    exit 0
fi

log_info "Step 1: Stopping Nix services..."
if sudo launchctl list | grep -q org.nixos.nix-daemon; then
    log_warn "Stopping nix-daemon service..."
    sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
    log_success "nix-daemon service stopped"
fi

for service in org.nixos.activate-system org.nixos.darwin-store; do
    if sudo launchctl list | grep -q $service; then
        log_warn "Stopping $service service..."
        sudo launchctl unload /Library/LaunchDaemons/$service.plist 2>/dev/null || true
        log_success "$service service stopped"
    fi
done

log_warn "Checking for processes using Nix store..."
if pgrep -f "/nix" > /dev/null; then
    log_warn "Found processes using Nix store, attempting to terminate..."
    sudo pkill -f "/nix" || true
    sleep 2
fi

log_info "Step 2: Removing configuration files..."
if [ -d /etc/nix ]; then
    log_warn "Removing /etc/nix..."
    sudo rm -rf /etc/nix
    log_success "Removed /etc/nix"
fi

if [ -d ~/.config/nix ]; then
    log_warn "Removing ~/.config/nix..."
    sudo rm -rf ~/.config/nix
    log_success "Removed ~/.config/nix"
fi

for file in "/etc/bashrc" "/etc/zshrc" "/etc/bash.bashrc" "/etc/zsh/zshrc"; do
    if [ -f "${file}.before-nix-darwin" ]; then
        log_warn "Restoring original ${file}..."
        sudo mv "${file}.before-nix-darwin" "${file}" || true
        log_success "Restored ${file}"
    elif [ -L "${file}" ]; then
        log_warn "Removing symlinked ${file}..."
        sudo rm -f "${file}" || true
        log_success "Removed ${file}"
    fi
done

if [ -d ~/.nix-defexpr ]; then
    log_warn "Removing ~/.nix-defexpr..."
    sudo rm -rf ~/.nix-defexpr
    log_success "Removed ~/.nix-defexpr"
fi

if [ -L ~/.nix-profile ]; then
    log_warn "Removing ~/.nix-profile..."
    sudo rm -f ~/.nix-profile
    log_success "Removed ~/.nix-profile"
fi

if [ -d ~/.local/state/nix ]; then
    log_warn "Removing ~/.local/state/nix..."
    sudo rm -rf ~/.local/state/nix
    log_success "Removed ~/.local/state/nix"
fi

log_info "Step 3: Removing launch daemons..."
for plist in /Library/LaunchDaemons/org.nixos.*.plist; do
    if [ -f "$plist" ]; then
        log_warn "Removing $plist..."
        sudo rm -f "$plist"
        log_success "Removed $plist"
    fi
done

log_info "Step 4: Removing Nix store and related files..."
for dir in /nix /var/root/.nix-profile /var/root/.nix-defexpr /var/root/.nix-channels; do
    if [ -e "$dir" ]; then
        log_warn "Removing $dir..."
        if [ "$dir" = "/nix" ] && [ -d "/nix/.Trashes" ]; then
            log_warn "Removing /nix/.Trashes directory with special permissions..."
            sudo rm -rf /nix/.Trashes 2>/dev/null || true
        fi
        sudo rm -rf "$dir" || log_warn "Warning: Could not fully remove $dir, continuing anyway"
        if [ ! -e "$dir" ]; then
            log_success "Removed $dir"
        else
            log_warn "Partial removal of $dir, some files may remain"
        fi
    fi
done

if [ -L /run/current-system ]; then
    log_warn "Removing /run/current-system symlink..."
    sudo rm -f /run/current-system
    log_success "Removed /run/current-system symlink"
fi

log_info "Step 5: Cleaning up backup files..."
log_warn "Removing system backup files..."
sudo rm -f /etc/*.before-nix-darwin || true
log_success "Removed system backup files"

log_warn "Removing home directory backup files..."
sudo rm -f "$HOME/.*.backup""*"" """"$HO"M"E"/.*.bak || true
log_success "Removed home directory backup files"

log_warn "Removing XDG config backup files..."
find "$HOME"/.config -name "*.backup" -o -name "*.bak" -exec sudo rm -f {} \; || true
log_success "Removed XDG config backup files"

if [ -d /etc/static ]; then
    log_warn "Removing /etc/static..."
    sudo rm -rf /etc/static
    log_success "Removed /etc/static"
fi

log_info "Step 6: Cleaning up shell configuration files..."
for file in "$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [ -f "$file" ]; then
        log_warn "Removing Nix references from $file..."
        sed -i.bak '/nix/d' "$file" || true
        sudo rm -f "${file}.bak" || true
        log_success "Cleaned up $file"
    fi
done

log_info "Step 7: Removing Nix users and groups..."
if dscl . -list /Groups | grep -q nixbld; then
    for i in $(seq 1 32); do
        nixbld="nixbld${i}"
        if dscl . -list /Users | grep -q "$nixbld"; then
            log_warn "Removing user $nixbld..."
            sudo dscl . -delete /Users/"$nixbld" || true
            log_success "Removed user $nixbld"
        fi
    done
    log_warn "Removing group nixbld..."
    sudo dscl . -delete /Groups/nixbld || true
    log_success "Removed group nixbld"
fi
