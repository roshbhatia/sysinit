#!/usr/bin/env bash
set -euo pipefail

NIX_CONFIG_DIR="${HOME}/.config/nix"
NIX_CONFIG="${NIX_CONFIG_DIR}/nix.conf"
SYSTEM_CUSTOM_CONF="/etc/nix/nix.custom.conf"

echo "Setting up user-level nix.conf"

# Create directory if needed
mkdir -p "${NIX_CONFIG_DIR}"

# Create/update nix.conf to include system custom config
{
  echo "# User-level Nix configuration"
  echo "# Includes system-wide configuration from /etc/nix/"
  echo ""
  echo "# Enable Nix 2.0 features"
  echo "experimental-features = nix-command flakes auto-allocate-uids impure-derivations dynamic-derivations"
  echo ""
  echo "# Trust current user for operations"
  echo "trusted-users = root $(whoami)"
  echo ""
  echo "# Include system-wide configuration (caches, substituters, secrets)"
  echo "!include ${SYSTEM_CUSTOM_CONF}"
} > "${NIX_CONFIG}"

echo "User nix.conf configured at ${NIX_CONFIG}"
echo "Access tokens from nix.secrets.conf will now be loaded when nix runs"
