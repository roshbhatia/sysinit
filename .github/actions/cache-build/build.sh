#!/usr/bin/env bash
set -euo pipefail

cache_name="$1"
shift
cache_work=$(mktemp -d)
derivations=()

publish_and_clean() {
  local status=$?
  if [ "${#derivations[@]}" -gt 0 ]; then
    if ! nix-store --query --requisites --include-outputs "${derivations[@]}" > "$cache_work/closure"; then
      [ "$status" -ne 0 ] || status=1
    else
      while IFS= read -r path; do
        case "$path" in
          *.drv) ;;
          *) printf '%s\n' "$path" ;;
        esac
      done < "$cache_work/closure" > "$cache_work/paths"
      if ! cachix push "$cache_name" < "$cache_work/paths"; then
        [ "$status" -ne 0 ] || status=1
      fi
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
