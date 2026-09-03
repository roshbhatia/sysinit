#!/usr/bin/env bash
set -euo pipefail

if defaults read -g AppleInterfaceStyle &> /dev/null; then
  printf '%s\n' dark
else
  printf '%s\n' light
fi
