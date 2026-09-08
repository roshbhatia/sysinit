#!/usr/bin/env bash

set -euo pipefail

# Installs this user's own CLIs (cloudTools) on a fresh cloud-agent box.
# Called by Claude Code cloud (setup-script field), Cursor cloud
# (.cursor/environment.json install), and Devin cloud (drs blueprint).
# The cloudTools closure substitutes wholesale from roshbhatia.cachix.org, so
# the box performs no source build.
#
# Generated from modules/shared/cloud.nix by flake/cloud-files.nix. Do not
# edit by hand; run hack/generate-cloud.sh.

CACHIX_URL="https://roshbhatia.cachix.org"
CACHIX_KEY="roshbhatia.cachix.org-1:K7Kq2esJYhrV/aCH8Xl7h54y8NULg/k+7WkObNT9VDk="
NIXOS_CACHE="https://cache.nixos.org"
INSTALLER_URL="https://install.determinate.systems/nix"
FLAKE_REF="github:roshbhatia/sysinit#packages.x86_64-linux.cloudTools"
BIN_DIR="/usr/local/bin"

# ln/mkdir under /usr/local need root; the box runs privileged, so sudo is a
# no-op fallback for the rare non-root shell.
as_root() {
  if [[ ${EUID} -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

install_nix() {
  if command -v nix > /dev/null 2>&1; then
    echo "nix already present, skipping installer"
    return
  fi
  echo "installing Determinate Nix"
  # Bake the substituters so the daemon trusts the key.
  curl --proto '=https' --tlsv1.2 -sSf -L "${INSTALLER_URL}" |
    sh -s -- install linux --init none --no-confirm --extra-conf 'sandbox = false' \
      --extra-conf "extra-substituters = ${CACHIX_URL} ${NIXOS_CACHE}" \
      --extra-conf "extra-trusted-public-keys = ${CACHIX_KEY}"
}

load_nix() {
  local profile="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  if [[ -f ${profile} ]]; then
    # shellcheck source=/dev/null
    . "${profile}"
  fi
}

build_tools() {
  echo "building ${FLAKE_REF}"
  nix build "${FLAKE_REF}" \
    --extra-experimental-features "nix-command flakes" \
    --extra-substituters "${CACHIX_URL}" \
    --extra-trusted-public-keys "${CACHIX_KEY}" \
    --out-link /tmp/sysinit-cloud-tools
}

link_tools() {
  local out
  out="$(readlink -f /tmp/sysinit-cloud-tools)"
  as_root mkdir -p "${BIN_DIR}"
  echo "linking ${out}/bin/* into ${BIN_DIR}"
  local f name
  for f in "${out}"/bin/*; do
    name="$(basename "${f}")"
    as_root ln -sf "${f}" "${BIN_DIR}/${name}"
  done
  echo "installed:"
  ls -1 "${out}/bin"
}

install_nix
load_nix
build_tools
link_tools
