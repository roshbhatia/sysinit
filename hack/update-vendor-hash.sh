#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OVERLAY_DIR="${REPO_ROOT}/overlays"

FAKE_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

# Restore every overlay this run has rewritten. Without it an interrupt leaves
# the fake hash on disk, and the automation PR commits it.
backups=()
# shellcheck disable=SC2329
restore() {
  local b
  for b in "${backups[@]:-}"; do
    [[ -f ${b} ]] && mv -f "${b}" "${b%.bak}"
  done
}
trap restore EXIT INT TERM

if [[ $# -gt 0 ]]; then
  packages=("$@")
  for pkg in "${packages[@]}"; do
    if [[ ! ${pkg} =~ ^[A-Za-z0-9_-]+$ ]]; then
      echo "ERROR: refusing package name '${pkg}'; it interpolates into a Nix expression" >&2
      exit 2
    fi
  done
else
  # Every overlay carrying a vendorHash, so a new Go package is covered on the
  # day it lands rather than when its hash first breaks a build.
  mapfile -t packages < <(grep -l 'vendorHash' "${OVERLAY_DIR}"/*.nix | xargs -n1 basename | sed 's/\.nix$//' | sort)
fi

status=0

for pkg in "${packages[@]}"; do
  overlay_file="${OVERLAY_DIR}/${pkg}.nix"

  if [[ ! -f ${overlay_file} ]]; then
    echo "SKIP: ${overlay_file} not found"
    continue
  fi

  if ! grep -q 'vendorHash' "${overlay_file}"; then
    echo "SKIP: ${pkg} has no vendorHash"
    continue
  fi

  echo "Updating vendorHash for ${pkg}..."

  cp "${overlay_file}" "${overlay_file}.bak"
  backups+=("${overlay_file}.bak")
  sed "s|vendorHash = .*|vendorHash = \"${FAKE_HASH}\";|" "${overlay_file}.bak" > "${overlay_file}"

  build_output=""
  rc=0
  build_output=$(nix build --no-link --impure --expr "
    let
      flake = builtins.getFlake \"path:${REPO_ROOT}\";
      pkgs = import flake.inputs.nixpkgs {
        system = builtins.currentSystem;
        overlays = [ flake.overlays.default ];
      };
    in pkgs.${pkg}
  " 2>&1) || rc=$?

  mv -f "${overlay_file}.bak" "${overlay_file}"
  backups=("${backups[@]/${overlay_file}.bak/}")

  if echo "${build_output}" | grep -q "vendor folder is empty"; then
    sed "s|vendorHash = .*|vendorHash = null;|" "${overlay_file}" > "${overlay_file}.tmp"
    mv "${overlay_file}.tmp" "${overlay_file}"
    echo "OK: ${pkg} vendorHash set to null (no vendor deps)"
    continue
  fi

  # Branch on the exit status. Searching the log for "error" misfired on a Go
  # file or dependency path that contains the word.
  if [[ ${rc} -eq 0 ]]; then
    echo "OK: ${pkg} built successfully"
    continue
  fi

  correct_hash=$(echo "${build_output}" | grep -o 'got: *sha256-[A-Za-z0-9+/]*=*' | head -1 | sed 's/got: *//' || true)

  if [[ -z ${correct_hash} ]]; then
    echo "ERROR: could not parse vendorHash for ${pkg}; build failed for another reason:" >&2
    echo "${build_output}" | tail -30 >&2
    status=1
    continue
  fi

  sed "s|vendorHash = .*|vendorHash = \"${correct_hash}\";|" "${overlay_file}" > "${overlay_file}.tmp"
  mv "${overlay_file}.tmp" "${overlay_file}"

  echo "OK: ${pkg} vendorHash updated to ${correct_hash}"
done

exit "${status}"
