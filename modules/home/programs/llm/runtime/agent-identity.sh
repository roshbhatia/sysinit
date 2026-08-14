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
agent_identity() {
  ai_cwd=${1:-$PWD}
  ai_pane=${2:-}

  ai_seshy_root=$(sysinit_path seshySessions) || ai_seshy_root="$HOME/.local/state/seshy/sessions"
  AI_SESSION=""
  case "$ai_cwd/" in
    "$ai_seshy_root"/*)
      ai_rest=${ai_cwd#"$ai_seshy_root"/}
      AI_SESSION=${ai_rest%%/*}
      ;;
  esac

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
