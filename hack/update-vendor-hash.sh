#!/usr/bin/env bash
set -euo pipefail

# Updates vendorHash for Go overlay packages by attempting a build with
# a fake hash and parsing the correct hash from the error output.
#
# Usage: ./hack/update-vendor-hash.sh [package...]
# If no packages specified, updates all known Go overlay packages.

OVERLAY_DIR="overlays"
GO_PACKAGES=("go-enum" "gomvp" "kubernetes-zeitgeist")

if [[ $# -gt 0 ]]; then
  packages=("$@")
else
  packages=("${GO_PACKAGES[@]}")
fi

for pkg in "${packages[@]}"; do
  overlay_file="${OVERLAY_DIR}/${pkg}.nix"

  if [[ ! -f "${overlay_file}" ]]; then
    echo "SKIP: ${overlay_file} not found"
    continue
  fi

  if ! grep -q 'vendorHash' "${overlay_file}"; then
    echo "SKIP: ${pkg} has no vendorHash"
    continue
  fi

  echo "Updating vendorHash for ${pkg}..."

  # Temporarily set vendorHash to a fake hash to force a mismatch
  cp "${overlay_file}" "${overlay_file}.bak"
  sed 's|vendorHash = .*|vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";|' "${overlay_file}.bak" > "${overlay_file}"

  # Attempt build and capture stderr (use the flake's own nixpkgs)
  build_output=""
  build_output=$(nix build --impure --expr "
    let
      flake = builtins.getFlake \"path:${PWD}\";
      pkgs = import flake.inputs.nixpkgs {
        system = builtins.currentSystem;
        overlays = [ flake.overlays.default ];
      };
    in pkgs.${pkg}
  " 2>&1) || true

  # Check if vendor folder is empty (vendorHash should be null)
  if echo "${build_output}" | grep -q "vendor folder is empty"; then
    mv "${overlay_file}.bak" "${overlay_file}"
    sed "s|vendorHash = .*|vendorHash = null;|" "${overlay_file}" > "${overlay_file}.tmp"
    mv "${overlay_file}.tmp" "${overlay_file}"
    echo "OK: ${pkg} vendorHash set to null (no vendor deps)"
    continue
  fi

  # Check if build succeeded (hash was already correct or no vendor needed)
  if ! echo "${build_output}" | grep -q "error"; then
    echo "OK: ${pkg} built successfully"
    mv "${overlay_file}.bak" "${overlay_file}"
    continue
  fi

  # Parse the correct hash from the build error
  # nix outputs: specified: sha256-FAKE got:    sha256-REAL
  correct_hash=$(echo "${build_output}" | grep -o 'got: *sha256-[A-Za-z0-9+/]*=*' | head -1 | sed 's/got: *//' || true)

  if [[ -z "${correct_hash}" ]]; then
    echo "ERROR: Could not parse vendorHash for ${pkg} from build output:"
    echo "${build_output}" | tail -30
    mv "${overlay_file}.bak" "${overlay_file}"
    continue
  fi

  # Restore original then write corrected hash
  mv "${overlay_file}.bak" "${overlay_file}"
  sed "s|vendorHash = .*|vendorHash = \"${correct_hash}\";|" "${overlay_file}" > "${overlay_file}.tmp"
  mv "${overlay_file}.tmp" "${overlay_file}"

  echo "OK: ${pkg} vendorHash updated to ${correct_hash}"
done
