#!/usr/bin/env bash
# Auto-detect which Nix configuration to use based on current directory

set -euo pipefail

# Get the absolute path of the current directory
CURRENT_DIR="$(pwd)"

# Check if we're in the work repo
if [[ ${CURRENT_DIR} == *"/github/work/"* ]]; then
  echo "work"
  exit 0
fi

# Check if we're in the personal repo
if [[ ${CURRENT_DIR} == *"/github/personal/"* ]]; then
  echo "lv426"
  exit 0
fi

# Default to lv426 if we can't determine
echo "lv426"
