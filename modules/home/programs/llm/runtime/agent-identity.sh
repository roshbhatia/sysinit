ai_workspace() {
  ai_pane=$1
  [ -n "$ai_pane" ] || return 0
  ai_wz=$(command -v wezterm 2> /dev/null || true)
  [ -n "$ai_wz" ] || return 0
  "$ai_wz" cli list --format json 2> /dev/null |
    jq -r --arg p "$ai_pane" '.[] | select((.pane_id | tostring) == $p) | .workspace' 2> /dev/null |
    head -1
}

# shellcheck disable=SC2034
# Three sources for the session, in cost order, and all three stay. Unlike
# `agentstate.go`, this file has readers with no other way to answer, so the
# workspace is still the last resort here.
#
#   1. the seshy session directory   a string operation on the cwd
#   2. ZMX_SESSION                   an environment lookup
#   3. the wezterm workspace         a fork, a pipe, and a jq
#
# Source 3 is why the order matters. `ai_workspace` forks `wezterm cli list` on
# every call made from inside wezterm, and it used to run unconditionally at the
# top of this function. It now runs only when the two cheaper sources are both
# empty. `AI_WORKSPACE` has no reader outside this file, so deferring it is safe
# for consumers, which is worth saying because deferring a variable usually is
# not.
#
# No grep can see this property: the gated call and the ungated call have the
# same text, and what changed is when it runs. `checks/agent-identity-fork.nix`
# checks it by behavior instead.
agent_identity() {
  ai_cwd=${1:-$PWD}
  ai_pane=${2:-}

  # sysinit:documented-default
  ai_seshy_root=$(sysinit_path seshySessions) || ai_seshy_root="$HOME/.local/state/seshy/sessions"
  AI_SESSION=""
  case "$ai_cwd/" in
    "$ai_seshy_root"/*)
      ai_rest=${ai_cwd#"$ai_seshy_root"/}
      AI_SESSION=${ai_rest%%/*}
      ;;
  esac

  # The prefix is a namespace, not part of the name, and the joins downstream
  # compare against unprefixed seshy names.
  if [ -z "$AI_SESSION" ] && [ -n "${ZMX_SESSION:-}" ]; then
    AI_SESSION=${ZMX_SESSION#"${ZMX_SESSION_PREFIX:-}"}
  fi

  AI_WORKSPACE=""
  if [ -z "$AI_SESSION" ]; then
    AI_WORKSPACE=$(ai_workspace "$ai_pane")
    if [ -n "$AI_WORKSPACE" ] && [ "$AI_WORKSPACE" != "default" ]; then
      AI_SESSION=$AI_WORKSPACE
    fi
  fi

  AI_REPO=""
  AI_BRANCH=""
  AI_DIRTY="false"
  AI_WORKTREE=""
  ai_toplevel=$(git -C "$ai_cwd" rev-parse --show-toplevel 2> /dev/null)
  if [ -n "$ai_toplevel" ]; then
    AI_WORKTREE=$ai_toplevel
    AI_REPO=$(basename "$ai_toplevel")
    AI_BRANCH=$(git -C "$ai_cwd" rev-parse --abbrev-ref HEAD 2> /dev/null)
    [ "$AI_BRANCH" = "HEAD" ] && AI_BRANCH=""
    if [ -n "$(git -C "$ai_cwd" status --porcelain 2> /dev/null)" ]; then
      AI_DIRTY="true"
    fi
  fi
}
