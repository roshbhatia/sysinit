#!/usr/bin/env bash
set -euo pipefail

echo "Checking Nix formatting"
if ! fd -e nix -E result -x nixfmt --width=100 --check; then
  echo "Nix formatting check failed. Run 'task fmt:nix' to fix"
  exit 1
fi
echo "Nix formatting is correct"
