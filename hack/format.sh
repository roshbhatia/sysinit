#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "${repo_root}"
if [ "${1:-}" != --check ]; then
  exec treefmt --config-file "${repo_root}/treefmt.toml" "$@"
fi
shift
format_tmp="$(mktemp -d "${TMPDIR:-/tmp}/sysinit-format.XXXXXX")"
trap 'rm -rf "${format_tmp:?}"' EXIT
while IFS= read -r -d '' file; do
  if [ -f "${file}" ]; then
    printf '%s\0' "${file}"
  fi
done < <(git ls-files -z) | tar -c --null -T - | tar -x -C "${format_tmp}"
exec_status=0
treefmt --config-file "${format_tmp}/treefmt.toml" --tree-root "${format_tmp}" \
  --working-dir "${format_tmp}" --walk filesystem --ci "$@" || exec_status=$?
exit "${exec_status}"
