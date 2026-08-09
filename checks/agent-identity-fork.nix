{
  pkgs,
  lib,
  ...
}:
# `agent_identity` must not fork `wezterm cli list` when a cheaper source
# answers.
#
# Phase 10's STOP gate. It lives in `checks/` rather than as prose in the task
# list, because prose runs once by hand and never again: a later edit to
# `agent-identity.sh` would silently remove the gate without failing anything.
# It is not in `.githooks/pre-commit` either, for the reason task 3.13 recorded
# when it moved a check out of there: that hook's idiom is skip-when-absent, and
# a guard that silently skips is the failure this check exists to catch.
#
# WHY BEHAVIORAL AND NOT A GREP. What changed in task 10.6 is WHEN the fork
# runs. The gated call and the ungated call have identical text, so no pattern
# distinguishes them.
#
# The technique has no precedent in this repository: nothing under `checks/` or
# `.githooks/` fakes a binary. It is introduced here and owed an explanation, so
# here it is. A stub named `wezterm` goes first on PATH, appends to a marker
# file, and exits non-zero. Its presence or absence after a call is the whole
# assertion.
#
# BOTH HALVES ARE NEEDED, and they fail in opposite directions:
#
#   half 1  a cheap source answers  ->  the marker must be ABSENT
#           proves the gate is there
#   half 2  no cheap source answers ->  the marker must be PRESENT
#           proves the gate did not become a deletion, which would take the
#           fallback away from the readers task 10.6 says must keep it
#
# THE FILE IS SOURCED, NOT RUN. `agent-identity.sh` defines two functions and
# has no top-level side effects, so executing it defines them and exits,
# producing no marker in either half and passing half one for the wrong reason.
#
# AND THE STUB CANNOT BE PUT ON THE PATH OF `agent-notify` OR `agent-prompt`.
# Those are the only two programs that embed this file, and both are
# `writeShellApplication`s listing `pkgs.wezterm` in `runtimeInputs`, which is
# prepended to PATH ahead of the inherited one. `command -v wezterm` would
# return the store binary and the stub would never run: half one would pass
# because the stub was unreachable rather than because the gate worked, and half
# two would fail on a correct implementation.
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
    # No errexit and no pipefail, to match production: the two applications that
    # embed this file both set `bashOptions = [ ]`. It also matters mechanically
    # here. `agent_identity` runs `git rev-parse` in a directory that is not a
    # repository, git exits 128, and under the generic builder's errexit that
    # kills the check before it asserts anything. That is what the first run of
    # this check did, with no output at all.
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

    # `agent-identity.sh` calls `sysinit_path`, which the runtime supplies. There
    # is no manifest in the sandbox, so the stub fails and the file takes its
    # documented default, which is the branch this check wants anyway.
    sysinit_path() { return 1; }

    export SYSINIT_FORK_MARKER="$PWD/forked.txt"

    . ${identity}

    fail() {
      echo "check-agent-identity-fork: $*" >&2
      exit 1
    }

    # --- half 1: ZMX_SESSION answers, so the fork must not run.
    #
    # The pane argument is NON-EMPTY on purpose. `ai_workspace` returns at its
    # third line when the pane is empty, so an empty argument would make this
    # half pass without the gate and would make half two assert a marker that
    # could never appear.
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
