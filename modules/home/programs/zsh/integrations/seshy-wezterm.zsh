#!/usr/bin/env zsh
# shellcheck disable=all

# seshy helpers — the multi-repo, git-worktree session manager binary is `sy`
_seshy_debug() {
  [[ -n $SYSINIT_DEBUG ]] && echo "[SESHY] $*" >&2
}

_seshy_err() {
  echo "seshy: $*" >&2
}

# Print session names, one per line (drops the `sy list` header row)
_seshy_names() {
  if ! command -v sy > /dev/null 2>&1; then
    _seshy_err "sy not found on PATH"
    return 1
  fi
  sy list 2> /dev/null | awk 'NR > 1 { print $1 }'
}

# s <name>: jump to the greedily-matched session
function s() {
  if (( $# == 0 )); then
    _seshy_err "usage: s <session>"
    return 1
  fi

  local target
  if ! target=$(sy --greedy "$1" 2> /dev/null) || [[ -z $target ]]; then
    _seshy_err "no session matches \"$1\""
    return 1
  fi

  _seshy_debug "resolved \"$1\" -> $target"
  cd "$target" || return
}

# sl: list session names
function sl() {
  _seshy_names
}

# si: fuzzy-pick a session and jump to it
function si() {
  local session
  session=$(_seshy_names | fzf --height 40% --reverse --prompt "session> ") || return
  if [[ -z $session ]]; then
    _seshy_debug "no session selected"
    return 0
  fi
  s "$session"
}

# WezTerm user-var helpers: clipboard and notifications over SSH
# Uses iTerm2-style SetUserVar escape sequences, which WezTerm
# forwards transparently even through nested SSH / tmux sessions.
function wezcopy() {
  local data
  if [[ -t 0 ]]; then
    data="$*"
  else
    data="$(cat)"
  fi
  printf "\033]1337;SetUserVar=%s=%s\007" wez_copy "$(printf '%s' "$data" | base64 | tr -d '\n')"
}

function weznot() {
  printf "\033]1337;SetUserVar=%s=%s\007" wez_not "$(printf '%s' "$1" | base64 | tr -d '\n')"
}

function wezmon() {
  local cmd="$*"
  eval "$cmd"
  local rc=$?
  if (( rc == 0 )); then
    weznot "'$cmd' completed successfully"
  else
    weznot "'$cmd' failed (exit $rc)"
  fi
  return $rc
}

# No `sy` wrapper here. It used to live in this file, but .zshrc is read only by
# interactive shells, so `zsh -c`, every script, and every agent's shell tool
# bypassed it completely. The gate is now a real executable on PATH ahead of
# seshy's own bin; see `sy-gate` in modules/home/programs/llm/config/notify.nix.
