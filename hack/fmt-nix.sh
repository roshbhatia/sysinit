#!/usr/bin/env bash
set -euo pipefail

echo "Formatting Nix files"
if ! fd -e nix -E result -x nixfmt --width=100; then
  echo "Nix formatting failed"
  exit 1
fi
echo "Nix files formatted successfully"
