#!/usr/bin/env bash
set -euo pipefail

if pgrep -xq rift; then
  version="$({ rift --version 2> /dev/null || true; } | head -1 | awk '{print $2}')"
  printf 'Rift %s\n' "${version}"
else
  printf '%s\n' 'Quartz Compositor'
fi
