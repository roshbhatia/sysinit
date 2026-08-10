#!/usr/bin/env bash
# `agent_identity` must not fork `wezterm cli list` when a cheaper source answers.
# No errexit: `agent_identity` runs `git rev-parse` outside a repository and git
# exits 128, which would kill the check before it asserts anything.
set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
identity="${repo_root}/modules/home/programs/llm/runtime/agent-identity.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/stub"
cat > "$work/stub/wezterm" << 'STUB'
#!/bin/sh
echo "forked" >> "$SYSINIT_FORK_MARKER"
exit 1
STUB
chmod +x "$work/stub/wezterm"
PATH="$work/stub:$PATH"
export PATH

# No manifest outside a switch, so the stub fails and the file takes its default.
sysinit_path() { return 1; }

SYSINIT_FORK_MARKER="$work/forked.txt"
export SYSINIT_FORK_MARKER

# shellcheck source=/dev/null
. "$identity"

fail() {
  echo "check-agent-identity-fork: $*" >&2
  exit 1
}

rm -f "$SYSINIT_FORK_MARKER"
ZMX_SESSION_PREFIX="seshy-"
ZMX_SESSION="seshy-alpha"
export ZMX_SESSION ZMX_SESSION_PREFIX

agent_identity "$work" 7

[ "$AI_SESSION" = "alpha" ] || fail "expected the session alpha, got '$AI_SESSION'"
[ ! -e "$SYSINIT_FORK_MARKER" ] || fail "forked wezterm while ZMX_SESSION answered"

rm -f "$SYSINIT_FORK_MARKER"
unset ZMX_SESSION ZMX_SESSION_PREFIX

agent_identity "$work" 7

[ -e "$SYSINIT_FORK_MARKER" ] || fail "the wezterm fallback is gone, not deferred"

echo "agent-identity-fork: both halves pass"
