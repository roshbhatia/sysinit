#!/usr/bin/env bash

set -euo pipefail

# Renders the cloud-agent files from modules/shared/cloud.nix and copies them
# to their repo paths. `--check` diffs instead of copying and exits 1 on
# drift; `checks/cloud-files.nix` runs the same comparison in `nix flake check`.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

check=false
case "${1:-}" in
  --check) check=true ;;
  "") ;;
  *)
    echo "usage: generate-cloud.sh [--check]" >&2
    exit 2
    ;;
esac

out="$(nix build --no-link --print-out-paths .#cloud-files)"

drift=0
while IFS= read -r rel; do
  rendered="${out}/${rel}"
  if cmp -s "${rendered}" "${rel}"; then
    continue
  fi
  drift=$((drift + 1))
  if [ "${check}" = true ]; then
    echo "DRIFT: ${rel}" >&2
    diff -u "${rel}" "${rendered}" >&2 || true
  else
    mode=644
    case "${rel}" in
      *.sh) mode=755 ;;
    esac
    install -m "${mode}" "${rendered}" "${rel}"
    echo "updated ${rel}"
  fi
done < <(cd "${out}" && find . -type l -o -type f | sed 's|^\./||' | sort)

if [ "${check}" = true ] && [ "${drift}" -gt 0 ]; then
  echo "${drift} cloud file(s) drift from modules/shared/cloud.nix; run hack/generate-cloud.sh" >&2
  exit 1
fi
[ "${drift}" -eq 0 ] && echo "OK: cloud files match their render"
exit 0
