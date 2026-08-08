#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
icons_dir="${repo_root}/modules/home/programs/llm/runtime/icons"

sources=(
  "claude|https://cdn.simpleicons.org/claude/D97757"
  "codex|https://upload.wikimedia.org/wikipedia/commons/0/04/ChatGPT_logo.svg"
  "gemini|https://cdn.simpleicons.org/googlegemini/4285F4"
  "cursor|https://cdn.simpleicons.org/cursor/000000"
  "opencode|https://cdn.simpleicons.org/opencode/000000"
  "pi|https://cdn.simpleicons.org/pi/000000"
  "copilot|https://cdn.simpleicons.org/githubcopilot/000000"
)

write=false
case "${1:-}" in
  --write) write=true ;;
  "") ;;
  *)
    echo "ERROR: unknown argument: $1" >&2
    exit 2
    ;;
esac

tmpdir="$(mktemp -d)"
cleanup() { rm -rf "${tmpdir}"; }
trap cleanup EXIT

drift=0
for entry in "${sources[@]}"; do
  name="${entry%%|*}"
  url="${entry#*|}"
  current="${icons_dir}/${name}.svg"
  fetched="${tmpdir}/${name}.svg"

  if ! curl -fsSL "${url}" -o "${fetched}"; then
    echo "ERROR: could not fetch ${name} from ${url}" >&2
    exit 1
  fi

  if ! head -c 512 "${fetched}" | grep -q '<svg'; then
    echo "ERROR: ${name} did not come back as SVG; refusing to vendor it" >&2
    exit 1
  fi

  if [ -f "${current}" ] && cmp -s "${current}" "${fetched}"; then
    continue
  fi

  drift=$((drift + 1))
  echo "DRIFT: ${name}"
  if [ "${write}" = true ]; then
    mkdir -p "${icons_dir}"
    cp "${fetched}" "${current}"
    echo "  updated ${current#"${repo_root}"/}"
  fi
done

if [ "${drift}" -eq 0 ]; then
  echo "agent icons: up to date"
  exit 0
fi

if [ "${write}" = false ]; then
  echo "agent icons: ${drift} file(s) drifted; re-run with --write to apply" >&2
  exit 1
fi

echo "agent icons: updated ${drift} file(s); review the diff before committing"
