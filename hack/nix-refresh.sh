#!/usr/bin/env bash
set -euo pipefail

config="${1:-lv426}"

if [ "${config}" == "work" ]; then
  WORK_SYSINIT=$(find "${WORK_REPO_PATH:-.}" -maxdepth 2 -type d -name "sysinit" 2>/dev/null | head -n 1)
  [ -z "${WORK_SYSINIT}" ] && exit 1
  cd "${WORK_SYSINIT}"
  NIX_MAX_JOBS=1 NIX_CORES=1 task nix:refresh:work
elif [ "${config}" == "arrakis" ]; then
  NIXPKGS_ALLOW_UNFREE=1 sudo nixos-rebuild switch --flake ".#${config}"
else
  NIXPKGS_ALLOW_UNFREE=1 sudo -E darwin-rebuild switch --flake ".#${config}" --impure
fi
