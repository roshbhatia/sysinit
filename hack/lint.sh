#!/usr/bin/env bash
# Every formatter and linter this repository runs. `.githooks/pre-commit` calls
# it on the staged files. CI calls it with `--all` over the whole tree, since CI
# never runs the hook.
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

# --------------------------------------------------------------- the nix rules

nix_files=$(files_matching '\.nix$')
if [ -n "$nix_files" ] && command -v ast-grep > /dev/null 2>&1; then
  # shellcheck disable=SC2086 # one path per argument is the point
  run ast-grep scan -c sgconfig.yml $nix_files
fi

# ------------------------------------------------------------------------- lua

lua_files=$(files_matching '\.lua$')
if [ -n "$lua_files" ] && command -v stylua > /dev/null 2>&1; then
  # shellcheck disable=SC2086
  run stylua --check $lua_files
fi

# ----------------------------------------------------------------------- shell

sh_files=$(files_matching '(\.sh|^\.githooks/[a-z-]+)$')
if [ -n "$sh_files" ] && command -v shellcheck > /dev/null 2>&1; then
  # `--shell=bash` rather than the shebang: the runtime fragments under
  # `modules/home/programs/llm/runtime/` carry no shebang, because
  # `modules/lib/shell.nix` strips it when it assembles them.
  # shellcheck disable=SC2086
  run shellcheck --shell=bash $sh_files
fi

# ------------------------------------------------------- the generated manifest

# `bootstrap/mise.toml` is derived from `bootstrap/tools.toml`. It is checked in
# so the bootstrap can read it on a box with no python, which means it can also
# be edited by hand or left behind when the manifest moves.
if [ "$scope" = all ] || [ -n "$(files_matching '^bootstrap/(tools|mise|mise-editor)\.toml$')" ]; then
  run bootstrap/gen-mise-toml.sh --check
fi

# --------------------------------------------------------- the openspec linters

if command -v citelock > /dev/null 2>&1; then
  while IFS= read -r lock; do
    [ -z "$lock" ] && continue
    run citelock verify "$(dirname "$lock")"
  done < <(find openspec/changes -name citations.lock 2> /dev/null)
fi

if command -v spec-preflight > /dev/null 2>&1; then
  while IFS= read -r change; do
    [ -z "$change" ] && continue
    run spec-preflight all "$change"
  done < <(
    files_matching '^openspec/changes/' |
      sed -n 's|^openspec/changes/\([^/]*\)/.*|\1|p' |
      grep -v '^archive$' |
      sort -u
  )
fi

exit "$status"
