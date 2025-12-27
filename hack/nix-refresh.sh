#!/usr/bin/env bash
set -euo pipefail

config="${1:-lv426}"

case "${config}" in
work)
  WORK_SYSINIT=$(fd -t d -d 2 "^sysinit$" ~/github/work 2>/dev/null | head -n 1)
  [ -z "${WORK_SYSINIT}" ] && {
    echo "Error: Could not find work sysinit directory" >&2
    exit 1
  }
  cd "${WORK_SYSINIT}"
  nh darwin switch ".#darwinConfigurations.work" --commit-lock-file --fallback --quiet
  ;;
arrakis)
  nh os switch ".#nixosConfigurations.${config}" --commit-lock-file --fallback --quiet
  ;;
lv426)
  nh os switch ".#darwinConfigurations.${config}" --commit-lock-file --fallback --quiet
  ;;
esac
