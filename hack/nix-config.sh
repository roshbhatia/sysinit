#!/usr/bin/env bash
set -euo pipefail

log_info() { echo "[INFO] $*"; }
log_success() { echo "[SUCCESS] $*"; }
log_error() { echo "[ERROR] $*"; }

log_info "Updating nix configuration"

# Copy custom config
if ! sudo cp nix.custom.conf /etc/nix/nix.custom.conf; then
  log_error "Failed to copy nix.custom.conf"
  exit 1
fi

# Copy secrets if they exist
if [ -f "nix.secrets.conf" ]; then
  if ! sudo cp nix.secrets.conf /etc/nix/nix.secrets.conf; then
    log_error "Failed to copy nix.secrets.conf"
    exit 1
  fi
  sudo chmod 600 /etc/nix/nix.secrets.conf
  log_success "Deployed nix.secrets.conf with restrictive permissions"
else
  log_info "nix.secrets.conf not found (run 'task nix:secrets:init' to create)"
fi

log_success "Nix configuration updated successfully"
log_info "Run 'sudo launchctl stop org.nixos.nix-daemon && sleep 2 && sudo launchctl start org.nixos.nix-daemon' to restart daemon with new config"
