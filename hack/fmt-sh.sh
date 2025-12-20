#!/usr/bin/env bash
set -euo pipefail

echo "Formatting shell files"
if ! fd -e sh -e bash -e zsh -x shfmt -i 2 -ci -sr -s -w; then
  echo "Shell formatting failed"
  exit 1
fi
echo "Shell files formatted successfully"
