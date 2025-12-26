#!/usr/bin/env bash
set -euo pipefail

config="${1:-lv426}"

case "${config}" in
  arrakis)
    nh os build ".#nixosConfigurations.arrakis"
    ;;
  work)
    nh darwin build ".#darwinConfigurations.work"
    ;;
  *)
    nh darwin build ".#darwinConfigurations.${config}"
    ;;
esac
