#!/usr/bin/env bash
# Fail when the harness registry and the neovim adapter list disagree.
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

registry="modules/home/programs/llm/harnesses/registry.nix"
adapters="modules/home/programs/neovim/config/lua/harness/registry.lua"

command -v nix > /dev/null 2>&1 || {
  echo "check-harness-registry: nix is not on PATH, skipping" >&2
  exit 0
}

from_registry=$(
  nix eval --raw --file "$registry" \
    --apply 'r: builtins.concatStringsSep "\n" (builtins.attrValues (builtins.mapAttrs (_: h: h.neovimAdapter) r))' |
    sort
)

# ORDER is a flat list of quoted names. Read it rather than the adapter files on
# disk, because a file the list does not name is never loaded.
from_adapters=$(
  awk '/^local ORDER = \{/ {inside = 1; next} inside && /^\}/ {exit} inside' "$adapters" |
    grep -o '"[^"]*"' | tr -d '"' | sort
)

if [ "$from_registry" = "$from_adapters" ]; then
  exit 0
fi

echo "harness-registry: $registry and $adapters disagree." >&2
comm -23 <(printf '%s\n' "$from_registry") <(printf '%s\n' "$from_adapters") |
  sed 's/^/  in the registry, not in ORDER: /' >&2
comm -13 <(printf '%s\n' "$from_registry") <(printf '%s\n' "$from_adapters") |
  sed 's/^/  in ORDER, not in the registry: /' >&2
echo "Add the harness to both, or correct its neovimAdapter field." >&2
exit 1
