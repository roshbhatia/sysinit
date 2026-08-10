{
  pkgs,
  lib,
  ...
}:
# `agent_identity` must not fork `wezterm cli list` when a cheaper source answers.
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
