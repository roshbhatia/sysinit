#!/usr/bin/env bash
set -euo pipefail

if pgrep -xq komorebi; then
  version="$(komorebi --version 2> /dev/null | head -1 || true)"
  printf 'komorebi %s\n' "${version}"
else
  printf '%s\n' 'Quartz Compositor'
fi
