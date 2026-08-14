#!/usr/bin/env bash

set -euo pipefail

OVERLAY_FILE="overlays/pretty-mermaid.nix"
LOCK_FILE="overlays/pretty-mermaid-package-lock.json"
REPO="imxv/Pretty-mermaid-skills"

CURRENT=$(grep -oE '"[0-9a-f]{40}"; # autoupdate:rev' "${OVERLAY_FILE}" | grep -oE '[0-9a-f]{40}')
LATEST=$(git ls-remote "https://github.com/${REPO}" HEAD | cut -f1)

if [[ -z ${LATEST} ]]; then
  echo "FAIL: could not read HEAD of ${REPO}" >&2
  exit 1
fi

if [[ ${LATEST} == "${CURRENT}" ]]; then
  echo "OK: pretty-mermaid already at ${CURRENT:0:7}"
  exit 0
fi

echo "Updating pretty-mermaid ${CURRENT:0:7} -> ${LATEST:0:7}..."

echo "  Computing src hash..."
RAW_HASH=$(nix-prefetch-url --type sha256 --unpack "https://github.com/${REPO}/archive/${LATEST}.tar.gz" 2> /dev/null)
SRC_HASH=$(nix hash convert --hash-algo sha256 --from nix32 --to sri "${RAW_HASH}")

echo "  Generating package-lock.json..."
WORKDIR=$(mktemp -d)
trap 'rm -rf "${WORKDIR}"' EXIT
curl -sL "https://github.com/${REPO}/archive/${LATEST}.tar.gz" | tar -xz -C "${WORKDIR}" --strip-components=1
(cd "${WORKDIR}" && npm install --package-lock-only --ignore-scripts --quiet 2> /dev/null)
cp "${WORKDIR}/package-lock.json" "${LOCK_FILE}"

echo "  Computing npm deps hash..."
NPM_DEPS_HASH=$(nix run nixpkgs#prefetch-npm-deps -- "${LOCK_FILE}" 2> /dev/null)

cp "${OVERLAY_FILE}" "${OVERLAY_FILE}.bak"
sed \
  -e "s|\"[0-9a-f]\{40\}\"; # autoupdate:rev|\"${LATEST}\"; # autoupdate:rev|" \
  -e "s|hash = \"[^\"]*\"; # autoupdate:src-hash|hash = \"${SRC_HASH}\"; # autoupdate:src-hash|" \
  -e "s|hash = \"[^\"]*\"; # autoupdate:npm-deps-hash|hash = \"${NPM_DEPS_HASH}\"; # autoupdate:npm-deps-hash|" \
  "${OVERLAY_FILE}.bak" > "${OVERLAY_FILE}"
rm "${OVERLAY_FILE}.bak"

echo "OK: pretty-mermaid updated to ${LATEST:0:7}"
echo "NOTE: the skill's ASCII routing was measured against 0.1.3 of beautiful-mermaid."
echo "      Re-render the class and state examples before trusting a new version's ASCII."
