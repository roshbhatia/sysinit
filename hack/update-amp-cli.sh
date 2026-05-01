#!/usr/bin/env bash
# Updates version, fetchzip src hash, package-lock.json, and fetchNpmDeps hash for
# the amp-cli overlay when a new npm release is detected.
#
# Requires: curl, jq, nix (with nix-prefetch-url), npm
# Usage: ./hack/update-amp-cli.sh

set -euo pipefail

OVERLAY_FILE="overlays/amp-cli.nix"
LOCK_FILE="overlays/amp-cli-package-lock.json"

CURRENT=$(grep -oP '(?<=version = ")[^"]+' "${OVERLAY_FILE}" | head -1)
LATEST=$(curl -sf "https://registry.npmjs.org/@sourcegraph/amp/latest" | jq -r '.version')

if [[ "${LATEST}" == "${CURRENT}" ]]; then
  echo "OK: amp-cli already at ${CURRENT}"
  exit 0
fi

echo "Updating amp-cli ${CURRENT} -> ${LATEST}..."

TGZ_URL="https://registry.npmjs.org/@sourcegraph/amp/-/amp-${LATEST}.tgz"

# Compute fetchzip hash (hash of unpacked content)
echo "  Computing src hash..."
RAW_HASH=$(nix-prefetch-url --type sha256 --unpack "${TGZ_URL}" 2>/dev/null)
SRC_HASH=$(nix hash convert --hash-algo sha256 --from nix32 --to sri "${RAW_HASH}")

# Generate wrapper package-lock.json with the new amp version.
# The overlay builds a thin wrapper package that imports @sourcegraph/amp,
# so the lock file tracks amp's full transitive dependency tree.
echo "  Generating package-lock.json..."
WORKDIR=$(mktemp -d)
trap 'rm -rf "${WORKDIR}"' EXIT

cat > "${WORKDIR}/package.json" <<EOF
{
  "name": "amp-cli",
  "version": "0.0.0",
  "license": "UNLICENSED",
  "dependencies": {
    "@sourcegraph/amp": "${LATEST}"
  },
  "bin": {
    "amp": "./bin/amp-wrapper.js"
  }
}
EOF
( cd "${WORKDIR}" && npm install --package-lock-only --ignore-scripts --quiet 2>/dev/null )
cp "${WORKDIR}/package-lock.json" "${LOCK_FILE}"

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

echo "OK: amp-cli updated to ${LATEST}"
