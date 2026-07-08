# agent-identity: shared session / repo / pane identity resolution.
#
# Concatenated at build time (see notify.nix) into BOTH agent-notify and
# agent-state so the two can never disagree about which session or repo a pane
# belongs to. Defines functions only — sourcing it has no side effects.
#
# `agent_identity <cwd> <pane>` populates these globals (all best-effort, all
# empty/false on failure, never a non-zero exit that could abort the caller):
#   AI_WORKSPACE  wezterm workspace for the pane (may be empty or "default")
#   AI_SESSION    resolved seshy session name (empty when none)
#   AI_REPO       basename of the git toplevel (empty outside a repo)
#   AI_BRANCH     current git branch (empty outside a repo / when detached)
#   AI_DIRTY      "true" when the worktree has uncommitted changes, else "false"
#   AI_WORKTREE   absolute git worktree root (empty outside a repo)

# wezterm workspace for a pane id, via `wezterm cli list`. Empty on any failure
# (no wezterm, no pane, no match). Mirrors the lookup agent-notify used inline.
ai_workspace() {
  ai_pane=$1
  [ -n "$ai_pane" ] || return 0
  ai_wz=$(command -v wezterm 2> /dev/null || true)
  [ -n "$ai_wz" ] || return 0
  "$ai_wz" cli list --format json 2> /dev/null |
    jq -r --arg p "$ai_pane" '.[] | select((.pane_id | tostring) == $p) | .workspace' 2> /dev/null |
    head -1
}

# Resolve the session/repo/git identity for a pane. Session prefers the
# cwd-under-seshy-root parse (reliable even when the pane's workspace is the
# unnamed default), then falls back to the wezterm workspace name.
#
# The AI_* globals are the resolver's public output; each caller consumes a
# different subset (agent-notify uses session/repo; agent-state uses all), so the
# static-analysis "appears unused" warning is expected — used-externally case.
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

  # git-derived fields; all empty/false outside a repo. Each call is guarded so a
  # non-repo cwd (or missing git) degrades silently.
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
