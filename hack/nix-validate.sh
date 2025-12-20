#!/usr/bin/env bash
set -euo pipefail

echo "Running Nix validation checks"

# Run flake check (validates format for Nix, Lua, Shell)
if ! nix flake check --no-build; then
  echo "Flake check failed (see errors above)"
  exit 1
fi

echo "Nix validation passed (format checks complete)"
