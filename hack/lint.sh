#!/usr/bin/env bash
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root" || exit 1

scope=staged
case ${1:-} in
  --all) scope=all ;;
  "") ;;
  *)
    echo "usage: lint.sh [--all]" >&2
    exit 2
    ;;
esac

status=0

run() {
  echo "==> $1"
  if ! "$@"; then
    echo "FAIL: $1" >&2
    status=1
  fi
}

files_matching() {
  if [ "$scope" = all ]; then
    git ls-files
  else
    git diff --cached --name-only --diff-filter=ACMR
  fi | grep -E "$1" || true
}

# nvfetcher writes _sources/generated.nix, so linting it reports drift nobody
# can fix in place.
nix_files=$(files_matching '\.nix$' | grep -v '^_sources/generated\.nix$')
if [ -n "$nix_files" ] && command -v ast-grep > /dev/null 2>&1; then
  # shellcheck disable=SC2086 # one path per argument is the point
  run ast-grep scan -c sgconfig.yml $nix_files
fi

# statix takes one target per invocation, so the file list needs a loop.
if [ -n "$nix_files" ] && command -v statix > /dev/null 2>&1; then
  echo "==> statix"
  for nix_file in $nix_files; do
    if ! statix check "$nix_file"; then
      echo "FAIL: statix $nix_file" >&2
      status=1
    fi
  done
fi

if [ -n "$nix_files" ] && command -v deadnix > /dev/null 2>&1; then
  # shellcheck disable=SC2086
  run deadnix --fail $nix_files
fi

lua_files=$(files_matching '\.lua$')
if [ -n "$lua_files" ] && command -v stylua > /dev/null 2>&1; then
  # shellcheck disable=SC2086
  run stylua --check $lua_files
fi

sh_files=$(files_matching '(\.sh|^\.githooks/[a-z-]+)$')
if [ -n "$sh_files" ] && command -v shellcheck > /dev/null 2>&1; then
  # shellcheck disable=SC2086
  run shellcheck --shell=bash $sh_files
fi

py_files=$(files_matching '\.py$')
if [ -n "$py_files" ]; then
  # shellcheck disable=SC2086
  run hack/check-script-blocks.sh $py_files
fi

exit "$status"
