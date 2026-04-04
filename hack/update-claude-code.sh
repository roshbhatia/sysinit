#!/usr/bin/env bash
# Updates version, fetchzip src hash, package-lock.json, and fetchNpmDeps hash for
# the claude-code overlay when a new npm release is detected.
#
# Requires: curl, jq, nix (with nix-prefetch-url), tar
# Usage: ./hack/update-claude-code.sh

set -euo pipefail

OVERLAY_FILE="overlays/claude-code.nix"
LOCK_FILE="overlays/claude-code-package-lock.json"

CURRENT=$(grep -oP '(?<=version = ")[^"]+' "${OVERLAY_FILE}" | head -1)
LATEST=$(curl -sf "https://registry.npmjs.org/@anthropic-ai/claude-code/latest" | jq -r '.version')

if [[ "${LATEST}" == "${CURRENT}" ]]; then
  echo "OK: claude-code already at ${CURRENT}"
  exit 0
fi

echo "Updating claude-code ${CURRENT} -> ${LATEST}..."

TGZ_URL="https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${LATEST}.tgz"

# Compute fetchzip hash (hash of unpacked content)
echo "  Computing src hash..."
RAW_HASH=$(nix-prefetch-url --type sha256 --unpack "${TGZ_URL}" 2>/dev/null)
SRC_HASH=$(nix hash convert --hash-algo sha256 --from nix32 --to sri "${RAW_HASH}")

# Extract package-lock.json from the tgz
echo "  Extracting package-lock.json..."
curl -sL "${TGZ_URL}" | tar -xzO package/package-lock.json > "${LOCK_FILE}"

# Compute fetchNpmDeps hash
echo "  Computing npm deps hash..."
NPM_DEPS_HASH=$(nix run nixpkgs#prefetch-npm-deps -- "${LOCK_FILE}" 2>/dev/null)

# Update overlay
cp "${OVERLAY_FILE}" "${OVERLAY_FILE}.bak"
sed \
  -e "s|version = \"[^\"]*\";|version = \"${LATEST}\";|" \
  -e "s|hash = \"[^\"]*\"; # autoupdate:src-hash|hash = \"${SRC_HASH}\"; # autoupdate:src-hash|" \
  -e "s|hash = \"[^\"]*\"; # autoupdate:npm-deps-hash|hash = \"${NPM_DEPS_HASH}\"; # autoupdate:npm-deps-hash|" \
  "${OVERLAY_FILE}.bak" > "${OVERLAY_FILE}"
rm "${OVERLAY_FILE}.bak"

echo "OK: claude-code updated to ${LATEST}"
