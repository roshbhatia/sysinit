#!/usr/bin/env bash
set -euo pipefail

config="${1:-lv426}"

if [ "${config}" == "work" ]; then
  WORK_SYSINIT=$(fd -t d -d 2 "^sysinit$" ~/github/work 2> /dev/null | head -n 1)
  [ -z "${WORK_SYSINIT}" ] && exit 1
  cd "${WORK_SYSINIT}"
  task nix:refresh:work
elif [ "${config}" == "arrakis" ]; then
  HOSTNAME=$(hostname)
  if [ "${HOSTNAME}" != "arrakis" ]; then
    ssh -t arrakis "ARRAKIS_SYSINIT=\$(fd -t d -d 2 '^sysinit$' ~/github/personal/roshbhatia 2>/dev/null | head -n 1) && cd \"\${ARRAKIS_SYSINIT}\" && git reset --hard && git pull && task nix:refresh:arrakis"
  else
    NIXPKGS_ALLOW_UNFREE=1 sudo nixos-rebuild switch --flake ".#${config}"
  fi
else
  NIXPKGS_ALLOW_UNFREE=1 sudo -E darwin-rebuild switch --flake ".#${config}" --impure
fi
