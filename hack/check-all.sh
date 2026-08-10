#!/usr/bin/env bash
# Every check `.githooks/pre-commit` runs, over the whole tree rather than the
# staged paths. This is what CI runs, since CI never runs the hook.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root" || exit 1

status=0

run() {
  echo "==> $1"
  if ! "$@"; then
    echo "FAIL: $1" >&2
    status=1
  fi
}

if command -v ast-grep > /dev/null 2>&1; then
  run ast-grep scan -c sgconfig.yml
fi

if command -v stylua > /dev/null 2>&1; then
  run stylua --check modules/
fi

run hack/check-state-paths.sh
run hack/check-harness-registry.sh
run hack/check-wezterm-chords.sh
run bootstrap/gen-mise-toml.sh --check
run hack/check-agent-identity-fork.sh
run hack/check-wezterm-lua.sh
run hack/check-llm-skill-destinations.sh
run hack/check-hunk-agent-context.sh

if command -v citelock > /dev/null 2>&1; then
  while IFS= read -r lock; do
    [[ -z ${lock} ]] && continue
    run citelock verify "$(dirname "$lock")"
  done < <(find openspec/changes -name citations.lock 2> /dev/null)
fi

exit "$status"
