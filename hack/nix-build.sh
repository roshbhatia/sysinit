#!/usr/bin/env bash
set -euo pipefail

config="${1:-lv426}"
shift 2>/dev/null || true

if [ "${config}" == "arrakis" ]; then
  NIXPKGS_ALLOW_UNFREE=1 nix build ".#nixosConfigurations.arrakis.config.system.build.toplevel" "$@"
elif [ "${config}" == "work" ]; then
  NIXPKGS_ALLOW_UNFREE=1 nix build ".#darwinConfigurations.work.system" "$@"
else
  NIXPKGS_ALLOW_UNFREE=1 nix build ".#darwinConfigurations.${config}.system" "$@"
fi
