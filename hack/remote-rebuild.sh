#!/usr/bin/env bash
# Remote NixOS rebuild helper script
# Usage: ./hack/remote-rebuild.sh [hostname] [--build-only]

set -euo pipefail

HOSTNAME="${1:-arrakis}"
BUILD_ONLY="${2:-}"

if [ "$BUILD_ONLY" = "--build-only" ]; then
  ACTION="build"
else
  ACTION="switch"
fi

echo "🔨 Remote rebuild on $HOSTNAME (action: $ACTION)"
echo "📍 Target: ${HOSTNAME}"
echo ""

# Ensure flake is up to date locally
echo "📦 Pulling latest changes..."
git pull

echo "🔄 Pushing to remote..."
git push

echo ""
echo "🚀 Rebuilding on $HOSTNAME..."

# Build the command as a single string to pass to SSH
if [ "$ACTION" = "build" ]; then
  REBUILD_CMD="cd /home/rshnbhatia/sysinit && git pull && nix flake update && nix build '.#nixosConfigurations.${HOSTNAME}.config.system.build.toplevel'"
else
  REBUILD_CMD="cd /home/rshnbhatia/sysinit && git pull && nix flake update && sudo nixos-rebuild switch --flake '.#${HOSTNAME}'"
fi

ssh "rshnbhatia@${HOSTNAME}" "$REBUILD_CMD"

echo ""
echo "✅ Remote rebuild complete!"
