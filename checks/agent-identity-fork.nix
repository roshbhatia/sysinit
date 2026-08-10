{
  pkgs,
  lib,
  ...
}:
# `agent_identity` must not fork `wezterm cli list` when a cheaper source answers.
#
# Behavioral, not a grep: the gated call and the ungated call have identical text.
# A stub `wezterm` goes first on PATH and appends to a marker file. Half one asserts
# the marker is absent when a cheap source answers; half two asserts it is present
# when none does, so the gate cannot become a deletion.
#
# The file is SOURCED, not run: it defines two functions and has no side effects.
# The stub cannot go on the PATH of `agent-notify` or `agent-prompt`, whose
# `runtimeInputs` prepend the store wezterm ahead of it.
let
  identity = ../modules/home/programs/llm/runtime/agent-identity.sh;
in
pkgs.runCommand "check-agent-identity-fork"
  {
    nativeBuildInputs = [
      pkgs.jq
      pkgs.git
    ];
    meta.description = "agent_identity does not fork wezterm when a cheaper source answers";
  }
  ''
    # No errexit: `agent_identity` runs `git rev-parse` outside a repository and git
    # exits 128, which would kill the check before it asserts anything.
    set +e
    set +o pipefail
    set -u

    mkdir -p stub
    cat > stub/wezterm <<'STUB'
    #!/bin/sh
    echo "forked" >> "$SYSINIT_FORK_MARKER"
    exit 1
    STUB
    chmod +x stub/wezterm
    export PATH="$PWD/stub:$PATH"

    # No manifest in the sandbox, so the stub fails and the file takes its default.
    sysinit_path() { return 1; }

    export SYSINIT_FORK_MARKER="$PWD/forked.txt"

    . ${identity}

    fail() {
      echo "check-agent-identity-fork: $*" >&2
      exit 1
    }

    # --- half 1: ZMX_SESSION answers, so the fork must not run.
    # The pane argument is NON-EMPTY on purpose: `ai_workspace` returns early on empty.
    rm -f "$SYSINIT_FORK_MARKER"
    ZMX_SESSION_PREFIX="seshy-"
    ZMX_SESSION="seshy-alpha"
    export ZMX_SESSION ZMX_SESSION_PREFIX

    agent_identity "$PWD" 7

    [ "$AI_SESSION" = "alpha" ] || fail "expected the session alpha, got '$AI_SESSION'"
    [ ! -e "$SYSINIT_FORK_MARKER" ] || fail "forked wezterm while ZMX_SESSION answered"

    # --- half 2: no cheap source, so the fork must run.
    rm -f "$SYSINIT_FORK_MARKER"
    unset ZMX_SESSION ZMX_SESSION_PREFIX

    agent_identity "$PWD" 7

    [ -e "$SYSINIT_FORK_MARKER" ] || fail "the wezterm fallback is gone, not deferred"

    echo "agent-identity-fork: both halves pass"
    touch $out
  ''
