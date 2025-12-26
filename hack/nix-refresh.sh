#!/usr/bin/env bash
set -euo pipefail

config="${1:-lv426}"
hostname=$(hostname)

case "${config}" in
  work)
    WORK_SYSINIT=$(fd -t d -d 2 "^sysinit$" ~/github/work 2>/dev/null | head -n 1)
    [ -z "${WORK_SYSINIT}" ] && {
      echo "Error: Could not find work sysinit directory" >&2
      exit 1
    }
    cd "${WORK_SYSINIT}"
    nh darwin switch ".#darwinConfigurations.work"
    ;;
  arrakis)
    if [ "${hostname}" != "arrakis" ]; then
      ssh arrakis "cd ~/github/personal/roshbhatia/sysinit && git reset --hard && git pull && nh os switch '.#nixosConfigurations.arrakis'"
    else
      nh os switch ".#nixosConfigurations.arrakis"
    fi
    ;;
  *)
    nh darwin switch ".#darwinConfigurations.${config}"
    ;;
esac
