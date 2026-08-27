#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

scope=staged
case "${1:-}" in
  --all) scope=all ;;
  "") ;;
  *)
    echo "usage: lint.sh [--all]" >&2
    exit 2
    ;;
esac

status=0
lint_tmp=""

# shellcheck disable=SC2329 # the EXIT trap invokes this function indirectly
cleanup() {
  if [ -n "${lint_tmp}" ]; then
    rm -rf "${lint_tmp:?}"
  fi
}
trap cleanup EXIT

run() {
  local label="$1"
  shift
  echo "==> ${label}" >&2
  if ! "$@"; then
    echo "FAIL: ${label}" >&2
    status=1
  fi
}

run_at() {
  local label="$1"
  local directory="$2"
  shift 2
  echo "==> ${label}" >&2
  if ! (cd "${directory}" && "$@"); then
    echo "FAIL: ${label}" >&2
    status=1
  fi
}

run_without_output() {
  local label="$1"
  shift
  local output
  echo "==> ${label}" >&2
  if ! output="$({ "$@"; } 2>&1)"; then
    printf '%s\n' "${output}" >&2
    echo "FAIL: ${label}" >&2
    status=1
  elif [ -n "${output}" ]; then
    printf '%s\n' "${output}" >&2
    echo "FAIL: ${label}" >&2
    status=1
  fi
}

files_matching() {
  local pattern="$1"
  if [ "${scope}" = all ]; then
    git ls-files
  else
    git diff --cached --name-only --diff-filter=ACMR
  fi | grep -E "${pattern}" || true
}

files_for() {
  local pattern="$1"
  local config_pattern="${2:-^$}"
  if [ "${scope}" = all ] || [ -n "$(files_matching "${config_pattern}")" ]; then
    git ls-files | grep -E "${pattern}" || true
  else
    files_matching "${pattern}"
  fi
}

ast_files=()
while IFS= read -r file; do
  [ -n "${file}" ] && ast_files+=("${file}")
done < <(files_for '\.(go|nix|py|ts|tsx)$' '(^sgconfig\.yml$|^\.ast-grep/rules/|/ast-grep/rules/)')
if [ "${#ast_files[@]}" -gt 0 ] && command -v ast-grep > /dev/null 2>&1; then
  run ast-grep ast-grep scan -c sgconfig.yml "${ast_files[@]}"
fi

nix_files=()
while IFS= read -r file; do
  if [ -n "${file}" ] && [ "${file}" != "_sources/generated.nix" ]; then
    nix_files+=("${file}")
  fi
done < <(files_for '\.nix$')
if [ "${#nix_files[@]}" -gt 0 ] && command -v statix > /dev/null 2>&1; then
  echo "==> statix" >&2
  for file in "${nix_files[@]}"; do
    if ! statix check "${file}"; then
      echo "FAIL: statix ${file}" >&2
      status=1
    fi
  done
fi
if [ "${#nix_files[@]}" -gt 0 ] && command -v deadnix > /dev/null 2>&1; then
  run deadnix deadnix --fail "${nix_files[@]}"
fi

lua_files=()
while IFS= read -r file; do
  [ -n "${file}" ] && lua_files+=("${file}")
done < <(files_for '\.lua$' '(^stylua\.toml$|(^|/)\.luarc\.json$)')
if [ "${#lua_files[@]}" -gt 0 ] && command -v stylua > /dev/null 2>&1; then
  run stylua stylua --check "${lua_files[@]}"
fi
if [ "${#lua_files[@]}" -gt 0 ] && command -v lua-language-server > /dev/null 2>&1; then
  lint_tmp="$(mktemp -d "${TMPDIR:-/tmp}/sysinit-lint.XXXXXX")"
  while IFS= read -r config; do
    [ -n "${config}" ] || continue
    root="${config%/.luarc.json}"
    name="${root//\//_}"
    run "lua-language-server ${root}" lua-language-server \
      --check="${root}" \
      --configpath="${config}" \
      --checklevel=Warning \
      --check_format=pretty \
      --logpath="${lint_tmp}/${name}-log" \
      --metapath="${lint_tmp}/${name}-meta"
  done < <(git ls-files | grep -E '(^|/)\.luarc\.json$' || true)
fi

go_files=()
while IFS= read -r file; do
  [ -n "${file}" ] && go_files+=("${file}")
done < <(files_for '\.go$' '(^\.golangci\.yml$|^pkgs/go\.(mod|sum)$)')
if [ "${#go_files[@]}" -gt 0 ] && command -v gofmt > /dev/null 2>&1; then
  run_without_output gofmt gofmt -l "${go_files[@]}"
fi
if [ "${#go_files[@]}" -gt 0 ] && command -v golangci-lint > /dev/null 2>&1; then
  run_at golangci-lint pkgs env GOPROXY=off golangci-lint run --config ../.golangci.yml ./...
fi

sh_files=()
while IFS= read -r file; do
  [ -n "${file}" ] && sh_files+=("${file}")
done < <(files_for '(\.sh$|^\.githooks/[a-z-]+$)')
if [ "${#sh_files[@]}" -gt 0 ] && command -v shellcheck > /dev/null 2>&1; then
  run shellcheck shellcheck --shell=bash "${sh_files[@]}"
fi

zsh_files=()
while IFS= read -r file; do
  [ -n "${file}" ] && zsh_files+=("${file}")
done < <(files_for '\.zsh$')
if [ "${#zsh_files[@]}" -gt 0 ] && command -v zsh > /dev/null 2>&1; then
  echo "==> zsh syntax" >&2
  for file in "${zsh_files[@]}"; do
    if ! zsh -n "${file}"; then
      echo "FAIL: zsh syntax ${file}" >&2
      status=1
    fi
  done
fi

nu_files=()
while IFS= read -r file; do
  [ -n "${file}" ] && nu_files+=("${file}")
done < <(files_for '\.nu$')
if [ "${#nu_files[@]}" -gt 0 ] && command -v nu > /dev/null 2>&1 && command -v jq > /dev/null 2>&1; then
  echo "==> nushell diagnostics" >&2
  for file in "${nu_files[@]}"; do
    if ! output="$(nu --no-config-file --ide-check 100 "${file}")"; then
      printf '%s\n' "${output}" >&2
      echo "FAIL: nushell diagnostics ${file}" >&2
      status=1
      continue
    fi
    diagnostics="$(printf '%s\n' "${output}" | jq -cs '[.[] | select(.type == "diagnostic")]')"
    if [ "${diagnostics}" != "[]" ]; then
      printf '%s\n' "${diagnostics}" | jq . >&2
      echo "FAIL: nushell diagnostics ${file}" >&2
      status=1
    fi
  done
fi

yaml_files=()
while IFS= read -r file; do
  [ -n "${file}" ] && yaml_files+=("${file}")
done < <(files_for '\.ya?ml$' '^\.yamllint\.yml$')
if [ "${#yaml_files[@]}" -gt 0 ] && command -v yamllint > /dev/null 2>&1; then
  run yamllint yamllint -c .yamllint.yml "${yaml_files[@]}"
fi
workflow_files=()
while IFS= read -r file; do
  [ -n "${file}" ] && workflow_files+=("${file}")
done < <(files_for '^\.github/workflows/.*\.ya?ml$')
if [ "${#workflow_files[@]}" -gt 0 ] && command -v actionlint > /dev/null 2>&1; then
  run actionlint actionlint "${workflow_files[@]}"
fi

json_files=()
while IFS= read -r file; do
  [ -n "${file}" ] && json_files+=("${file}")
done < <(files_for '\.json$')
if [ "${#json_files[@]}" -gt 0 ] && command -v jq > /dev/null 2>&1; then
  echo "==> JSON syntax" >&2
  for file in "${json_files[@]}"; do
    if ! jq empty "${file}"; then
      echo "FAIL: JSON syntax ${file}" >&2
      status=1
    fi
  done
fi

toml_files=()
while IFS= read -r file; do
  [ -n "${file}" ] && toml_files+=("${file}")
done < <(files_for '\.toml$')
if [ "${#toml_files[@]}" -gt 0 ] && command -v taplo > /dev/null 2>&1; then
  run taplo taplo lint --no-schema "${toml_files[@]}"
fi

cue_files=()
while IFS= read -r file; do
  [ -n "${file}" ] && cue_files+=("${file}")
done < <(files_for '\.cue$')
if [ "${#cue_files[@]}" -gt 0 ] && command -v cue > /dev/null 2>&1; then
  run "cue vet" cue vet "${cue_files[@]}"
fi

c_files=()
while IFS= read -r file; do
  [ -n "${file}" ] && c_files+=("${file}")
done < <(files_for '\.(c|h)$')
if [ "${#c_files[@]}" -gt 0 ] && [ "$(uname -s)" = Darwin ] && command -v clang > /dev/null 2>&1; then
  run "C syntax" clang -fsyntax-only "${c_files[@]}"
fi

svg_files=()
while IFS= read -r file; do
  [ -n "${file}" ] && svg_files+=("${file}")
done < <(files_for '\.svg$')
if [ "${#svg_files[@]}" -gt 0 ] && command -v xmllint > /dev/null 2>&1; then
  run "SVG syntax" xmllint --noout "${svg_files[@]}"
fi

ts_files=()
while IFS= read -r file; do
  [ -n "${file}" ] && ts_files+=("${file}")
done < <(files_for '\.tsx?$' '^tsconfig\.json$')
if [ "${#ts_files[@]}" -gt 0 ] && command -v tsc > /dev/null 2>&1; then
  run "TypeScript syntax" tsc --project tsconfig.json
fi

js_files=()
while IFS= read -r file; do
  [ -n "${file}" ] && js_files+=("${file}")
done < <(files_for '\.(js|mjs)$' '^eslint\.config\.mjs$')
if [ "${#js_files[@]}" -gt 0 ] && command -v eslint > /dev/null 2>&1; then
  run eslint eslint "${js_files[@]}"
fi

py_files=()
while IFS= read -r file; do
  [ -n "${file}" ] && py_files+=("${file}")
done < <(files_for '\.py$')
if [ "${#py_files[@]}" -gt 0 ]; then
  run "Python script blocks" hack/check-script-blocks.sh "${py_files[@]}"
fi

exit "${status}"
