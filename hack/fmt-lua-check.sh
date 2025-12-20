#!/usr/bin/env bash
set -euo pipefail

echo "Checking Lua formatting"
if ! fd -e lua -x stylua --check; then
  echo "Lua formatting check failed. Run 'task fmt:lua' to fix"
  exit 1
fi
echo "Lua formatting is correct"
