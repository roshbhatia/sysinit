#!/usr/bin/env bash
# Updates version and all hashes for the openspec overlay when a new npm release
# is detected. Uses the fake-hash technique for fetchPnpmDeps.
#
# Requires: curl, jq, nix (with nix-prefetch-url and nix build)
# Usage: ./hack/update-openspec.sh

set -euo pipefail

OVERLAY_FILE="overlays/openspec.nix"

CURRENT=$(grep -oP '(?<=version = ")[^"]+' "${OVERLAY_FILE}" | head -1)
LATEST=$(curl -sf "https://registry.npmjs.org/@fission-ai/openspec/latest" | jq -r '.version')

if [[ "${LATEST}" == "${CURRENT}" ]]; then
  echo "OK: openspec already at ${CURRENT}"
  exit 0
fi

echo "Updating openspec ${CURRENT} -> ${LATEST}..."

TGZ_URL="https://registry.npmjs.org/@fission-ai/openspec/-/openspec-${LATEST}.tgz"
PNPM_LOCK_URL="https://raw.githubusercontent.com/Fission-AI/OpenSpec/v${LATEST}/pnpm-lock.yaml"

# Compute fetchurl hash for the npm tgz
echo "  Computing src hash..."
RAW_SRC=$(nix-prefetch-url --type sha256 "${TGZ_URL}" 2>/dev/null)
SRC_HASH=$(nix hash convert --hash-algo sha256 --from nix32 --to sri "${RAW_SRC}")

# Compute fetchurl hash for the pnpm-lock.yaml
echo "  Computing pnpm-lock hash..."
RAW_LOCK=$(nix-prefetch-url --type sha256 "${PNPM_LOCK_URL}" 2>/dev/null)
PNPM_LOCK_HASH=$(nix hash convert --hash-algo sha256 --from nix32 --to sri "${RAW_LOCK}")

# Write updated overlay with new version + src/lock hashes, fake pnpm-deps hash
cp "${OVERLAY_FILE}" "${OVERLAY_FILE}.bak"
sed \
  -e "s|version = \"[^\"]*\";|version = \"${LATEST}\";|" \
  -e "s|hash = \"[^\"]*\"; # autoupdate:src-hash|hash = \"${SRC_HASH}\"; # autoupdate:src-hash|g" \
  -e "s|hash = \"[^\"]*\"; # autoupdate:pnpm-lock-hash|hash = \"${PNPM_LOCK_HASH}\"; # autoupdate:pnpm-lock-hash|" \
  -e "s|hash = \"[^\"]*\"; # autoupdate:pnpm-deps-hash|hash = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\"; # autoupdate:pnpm-deps-hash|" \
  "${OVERLAY_FILE}.bak" > "${OVERLAY_FILE}"
rm "${OVERLAY_FILE}.bak"

# Use a fake-hash build to extract the real fetchPnpmDeps hash
echo "  Computing pnpm deps hash (fake-hash build)..."
build_output=$(nix build --impure --expr "
  let
    flake = builtins.getFlake \"path:${PWD}\";
    pkgs = import flake.inputs.nixpkgs {
      system = builtins.currentSystem;
      overlays = [ flake.overlays.default ];
    };
  in pkgs.openspec
" 2>&1) || true

PNPM_DEPS_HASH=$(echo "${build_output}" | grep -o 'got: *sha256-[A-Za-z0-9+/=]*' | head -1 | sed 's/got: *//' || true)

if [[ -z "${PNPM_DEPS_HASH}" ]]; then
  echo "ERROR: Could not parse fetchPnpmDeps hash from build output:"
  echo "${build_output}" | tail -30
  mv "${OVERLAY_FILE}.bak" "${OVERLAY_FILE}" 2>/dev/null || true
  exit 1
fi

# Write correct pnpm-deps hash
sed -i "s|hash = \"[^\"]*\"; # autoupdate:pnpm-deps-hash|hash = \"${PNPM_DEPS_HASH}\"; # autoupdate:pnpm-deps-hash|" \
  "${OVERLAY_FILE}"

echo "OK: openspec updated to ${LATEST}"
