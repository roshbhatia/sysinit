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
ssh -t "rshnbhatia@${HOSTNAME}" << 'EOF'
set -euo pipefail
cd /home/rshnbhatia/sysinit || cd /root/sysinit

echo "📥 Pulling latest from git..."
git pull

echo "🔄 Updating flake inputs..."
nix flake update

if [ "$ACTION" = "build" ]; then
    echo "🏗️  Building configuration (no activation)..."
    nix build ".#nixosConfigurations.${HOSTNAME}.config.system.build.toplevel"
else
    echo "🚀 Building and applying configuration..."
    sudo nixos-rebuild switch --flake ".#${HOSTNAME}"
fi

echo "✅ Done!"
EOF

echo ""
echo "✅ Remote rebuild complete!"
