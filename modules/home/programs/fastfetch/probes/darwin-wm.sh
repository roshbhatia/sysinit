#!/usr/bin/env bash
set -euo pipefail

if pgrep -xq AeroSpace; then
  version="$({ aerospace --version 2> /dev/null || true; } | head -1 | awk '{print $5}')"
  printf 'AeroSpace %s\n' "${version}"
else
  printf '%s\n' 'Quartz Compositor'
fi
