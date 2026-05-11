#!/usr/bin/env bash
# Verifies that the repo-root AGENTS.md matches the generated content from
# `instructions.nix`. Exits non-zero on drift. Run after editing AGENTS.md
# or any input section in instructions.nix to confirm they stay aligned.
#
# Usage: ./hack/check-agents-md.sh

set -euo pipefail

GENERATED=$(nix build .#packages.aarch64-darwin.agentsMd --no-link --print-out-paths 2> /dev/null)

if [[ -z ${GENERATED} ]] || [[ ! -f ${GENERATED} ]]; then
  echo "ERROR: nix build .#agentsMd did not produce an output path" >&2
  exit 2
fi

if ! diff -q AGENTS.md "${GENERATED}" > /dev/null 2>&1; then
  echo "DRIFT: AGENTS.md differs from instructions.nix output"
  diff -u AGENTS.md "${GENERATED}" || true
  echo ""
  echo "To reconcile, run:" >&2
  echo '  cp "$(nix build .#packages.aarch64-darwin.agentsMd --no-link --print-out-paths)" AGENTS.md' >&2
  exit 1
fi

echo "OK: AGENTS.md matches instructions.nix output"
