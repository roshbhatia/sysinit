#!/usr/bin/env bash
set -euo pipefail

echo "Checking shell formatting"
if ! fd -e sh -e bash -e zsh -x shfmt -i 2 -ci -sr -s -d; then
  echo "Shell formatting check failed. Run 'task fmt:sh' to fix"
  exit 1
fi
echo "Shell formatting is correct"
