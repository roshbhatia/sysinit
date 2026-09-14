#!/usr/bin/env bash
set -euo pipefail

cache_name="$1"
shift
cache_work=$(mktemp -d)
derivations=()

publish_and_clean() {
  local status=$?
  if [ "${#derivations[@]}" -gt 0 ]; then
    if ! nix-store --query --requisites --include-outputs "${derivations[@]}" \
      | awk '!/\.drv$/' > "$cache_work/paths"; then
      [ "$status" -ne 0 ] || status=1
    elif ! cachix push "$cache_name" < "$cache_work/paths"; then
      [ "$status" -ne 0 ] || status=1
    fi
  fi
  rm -rf "${cache_work:?}"
  exit "$status"
}
trap publish_and_clean EXIT

nix path-info --derivation "$@" > "$cache_work/derivations"
targets=()
while IFS= read -r derivation; do
  derivations+=("$derivation")
  targets+=("$derivation^*")
done < "$cache_work/derivations"
nix build --out-link result --print-build-logs --keep-going "${targets[@]}"
