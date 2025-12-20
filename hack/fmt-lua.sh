#!/usr/bin/env bash
set -euo pipefail

echo "Formatting Lua files"
if ! fd -e lua -x stylua; then
  echo "Lua formatting failed"
  exit 1
fi
echo "Lua files formatted successfully"
