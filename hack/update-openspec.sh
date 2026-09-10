#!/usr/bin/env bash
set -euo pipefail

OVERLAY_FILE="overlays/openspec/default.nix"
FAKE_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

build_openspec() {
  nix build --no-link --impure --expr "
    let
      flake = builtins.getFlake \"path:${PWD}\";
      pkgs = import flake.inputs.nixpkgs {
        system = builtins.currentSystem;
        overlays = [ flake.overlays.default ];
      };
    in pkgs.openspec
  " 2>&1
}

for marker in src-hash pnpm-deps-hash; do
  if [[ $(grep -c "# autoupdate:${marker}$" "${OVERLAY_FILE}") != 1 ]]; then
    echo "ERROR: Expected one ${marker} marker in ${OVERLAY_FILE}" >&2
    exit 1
  fi
done

LATEST=$(curl -fsS 'https://registry.npmjs.org/@fission-ai/openspec/latest' | jq -er '.version')
if [[ ! ${LATEST} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "ERROR: Invalid OpenSpec version: ${LATEST}" >&2
  exit 1
fi

update_backup=$(mktemp)
cp "${OVERLAY_FILE}" "${update_backup}"
update_complete=false
cleanup() {
  if [[ ${update_complete} != true ]]; then
    cp "${update_backup}" "${OVERLAY_FILE}"
  fi
  rm -f "${update_backup}" "${OVERLAY_FILE}.bak"
}
trap cleanup EXIT

echo "Updating OpenSpec to ${LATEST} from its Git tag..." >&2
RAW_SRC=$(nix-prefetch-url --unpack --type sha256 "https://github.com/Fission-AI/OpenSpec/archive/refs/tags/v${LATEST}.tar.gz")
SRC_HASH=$(nix hash convert --hash-algo sha256 --from nix32 --to sri "${RAW_SRC}")
sed -i.bak \
  -e "s|version = \"[^\"]*\";|version = \"${LATEST}\";|" \
  -e "s|hash = \"[^\"]*\"; # autoupdate:src-hash|hash = \"${SRC_HASH}\"; # autoupdate:src-hash|" \
  -e "s|hash = \"[^\"]*\"; # autoupdate:pnpm-deps-hash|hash = \"${FAKE_HASH}\"; # autoupdate:pnpm-deps-hash|" \
  "${OVERLAY_FILE}"

if build_output=$(build_openspec); then
  echo 'ERROR: Expected a dependency hash mismatch with the placeholder hash' >&2
  exit 1
fi
DEPS_HASH=$(printf '%s\n' "${build_output}" | sed -n 's/.*got: *\(sha256-[A-Za-z0-9+/=]*\).*/\1/p')
if [[ ! ${DEPS_HASH} =~ ^sha256-[A-Za-z0-9+/=]+$ ]] || ! [[ ${build_output} == *openspec-pnpm-deps* ]]; then
  printf 'ERROR: OpenSpec dependency hash calculation failed:\n%s\n' "${build_output}" >&2
  exit 1
fi
sed -i.bak \
  -e "s|hash = \"[^\"]*\"; # autoupdate:pnpm-deps-hash|hash = \"${DEPS_HASH}\"; # autoupdate:pnpm-deps-hash|" \
  "${OVERLAY_FILE}"
build_openspec >&2
update_complete=true
echo "OK: OpenSpec ${LATEST} source, dependencies, and build verified" >&2
