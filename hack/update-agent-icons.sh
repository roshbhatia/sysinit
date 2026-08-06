#!/usr/bin/env bash
# Refresh the vendored agent notification icons.
#
# The icons under modules/home/programs/llm/runtime/icons/ are vendored rather
# than fetched at build time: cdn.simpleicons.org answers 403 to GitHub's
# runners while serving everyone else, so a `fetchurl` made every cold CI build
# depend on a third party's willingness to serve us.
#
# This script is the only thing that updates them, and it is never automatic.
# It reports drift and, unless --write is passed, changes nothing.
#
# Usage:
#   hack/update-agent-icons.sh            # report drift only
#   hack/update-agent-icons.sh --write    # apply it

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
icons_dir="${repo_root}/modules/home/programs/llm/runtime/icons"

# name|url. Keep in step with `svgs` in
# modules/home/programs/llm/runtime/default.nix: a name here with no attribute
# there ships a file nothing reads, and the reverse fails the build.
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

  # Failing here is the point: a 403 or a moved URL should be loud, not a
  # silently stale icon.
  if ! curl -fsSL "${url}" -o "${fetched}"; then
    echo "ERROR: could not fetch ${name} from ${url}" >&2
    exit 1
  fi

  # An empty or non-SVG body means the CDN served an error page with a 200.
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
