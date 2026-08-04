# Shared session/repo/pane identity, concatenated into agent-notify and
# agent-state at build time so the two cannot disagree.
#
# `agent_identity <cwd> <pane>` sets AI_WORKSPACE, AI_SESSION, AI_REPO,
# AI_BRANCH, AI_DIRTY, AI_WORKTREE. All best-effort, empty on failure.

ai_workspace() {
  ai_pane=$1
  [ -n "$ai_pane" ] || return 0
  ai_wz=$(command -v wezterm 2> /dev/null || true)
  [ -n "$ai_wz" ] || return 0
  "$ai_wz" cli list --format json 2> /dev/null |
    jq -r --arg p "$ai_pane" '.[] | select((.pane_id | tostring) == $p) | .workspace' 2> /dev/null |
    head -1
}

# Session prefers the cwd-under-seshy-root parse, which is reliable even when the
# pane's workspace is the unnamed default.
#
# shellcheck disable=SC2034
agent_identity() {
  ai_cwd=${1:-$PWD}
  ai_pane=${2:-}

  AI_WORKSPACE=$(ai_workspace "$ai_pane")

  ai_seshy_root="$HOME/.local/state/seshy/sessions"
  AI_SESSION=""
  case "$ai_cwd/" in
    "$ai_seshy_root"/*)
      ai_rest=${ai_cwd#"$ai_seshy_root"/}
      AI_SESSION=${ai_rest%%/*}
      ;;
  esac
  # wezterm's unnamed default workspace is not a session — ignore it.
  if [ -z "$AI_SESSION" ] && [ -n "$AI_WORKSPACE" ] && [ "$AI_WORKSPACE" != "default" ]; then
    AI_SESSION=$AI_WORKSPACE
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
