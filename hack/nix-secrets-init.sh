#!/usr/bin/env bash
set -euo pipefail

SECRETS_FILE="nix.secrets.conf"
SYSTEM_SECRETS_FILE="/etc/nix/nix.secrets.conf"

# Function to check if secrets file is valid
is_secrets_file_valid() {
  [ -f "$1" ] && grep -q '^[^#]*access-tokens[[:space:]]*=' "$1"
}

# Function to create secrets file with token
create_secrets_file() {
  local token="$1"
  {
    echo "# Nix secrets configuration"
    echo "# GitHub Personal Access Token for private repository access"
    echo "access-tokens = github.com=${token}"
  } > "${SECRETS_FILE}"
  chmod 600 "${SECRETS_FILE}"
}

# Function to deploy secrets to system
deploy_secrets() {
  echo "Deploying secrets to ${SYSTEM_SECRETS_FILE}"
  if ! sudo cp "${SECRETS_FILE}" "${SYSTEM_SECRETS_FILE}"; then
    echo "Failed to copy secrets to system directory"
    return 1
  fi
  sudo chmod 600 "${SYSTEM_SECRETS_FILE}"

  echo "To apply new secrets, restart nix-daemon:"
  echo "sudo launchctl stop org.nixos.nix-daemon && sleep 2 && sudo launchctl start org.nixos.nix-daemon"
  return 0
}

echo "Initializing nix secrets configuration"

# Check if valid secrets file already exists
if is_secrets_file_valid "${SECRETS_FILE}"; then
  echo "Valid nix.secrets.conf already exists"

  # Ensure it's deployed to system (use sudo for reading system file)
  if [ ! -f "${SYSTEM_SECRETS_FILE}" ] || ! sudo grep -q '^[^#]*access-tokens[[:space:]]*=' "${SYSTEM_SECRETS_FILE}" 2> /dev/null; then
    if deploy_secrets; then
      echo "Secrets deployed to system"
    fi
  else
    echo "Secrets already deployed to system"
  fi
  exit 0
fi

# Try to get token from gh CLI
echo "Attempting to get GitHub token from gh CLI"
if command -v gh > /dev/null 2>&1; then
  if GITHUB_TOKEN=$(gh auth token 2> /dev/null); then
    echo "Retrieved token from gh CLI"
    create_secrets_file "${GITHUB_TOKEN}"

    if deploy_secrets; then
      echo "Secrets initialized and deployed successfully"
      exit 0
    else
      exit 1
    fi
  else
    echo "gh CLI is installed but not authenticated"
    echo "Run 'gh auth in' to authenticate, then re-run this task"
  fi
else
  echo "gh CLI not found in PATH"
  echo "Authenticate with gh CLI: gh auth in"
fi

# If we get here, we couldn't auto-configure
echo "Could not automatically configure GitHub authentication"
exit 0
