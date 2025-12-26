#!/usr/bin/env bash
set -euo pipefail

config="${1:-lv426}"

case "${config}" in
  arrakis)
    nh os build ".#arrakis"
    ;;
  work)
    nh darwin build ".#work"
    ;;
  *)
    nh darwin build ".#${config}"
    ;;
esac
