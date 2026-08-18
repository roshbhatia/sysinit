#!/usr/bin/env zsh
# shellcheck disable=all

_seshy_debug() {
  [[ -n $SYSINIT_DEBUG ]] && echo "[SESHY] $*" >&2
}

_seshy_err() {
  echo "seshy: $*" >&2
}

_seshy_names() {
  if ! command -v sy > /dev/null 2>&1; then
    _seshy_err "sy not found on PATH"
    return 1
  fi
  sy list 2> /dev/null | awk 'NR > 1 { print $1 }'
}

_seshy_session_name() {
  local dir=$1 root
  root=$(sysinit_path seshySessions 2> /dev/null) || root="$HOME/.local/state/seshy/sessions"
  case "$dir/" in
    "$root"/*)
      dir=${dir#"$root"/}
      echo "${dir%%/*}"
      ;;
    *) echo "" ;;
  esac
}

_seshy_export_workspace() {
  local session root
  session=$(_seshy_session_name "$PWD")
  if [[ -z $session ]]; then
    unset SYSINIT_WORKSPACE
    return 0
  fi
  root=$(sysinit_path seshySessions 2> /dev/null) || root="$HOME/.local/state/seshy/sessions"
  export SYSINIT_WORKSPACE="$root/$session"
  _seshy_debug "workspace $SYSINIT_WORKSPACE"
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _seshy_export_workspace
_seshy_export_workspace

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

# zmx holds terminal state in libghostty-vt and hands the client a grid snapshot,
# so OSC never crosses it. Measured: a wrapped pane loses OSC 7 (wezterm reads
# zmx's own cwd) and OSC 1337 SetUserVar (agent_state, IS_NVIM, wezcopy). `s`
# used to attach on every switch, which put every agent behind that boundary.
# Attaching is deliberate now, and `sz` is where you say so.
function sz() {
  if ! command -v zmx > /dev/null 2>&1; then
    _seshy_err "zmx not found on PATH"
    return 1
  fi

  local session
  session=$(_seshy_session_name "$PWD")
  if [[ -z $session ]]; then
    _seshy_err "$PWD is not inside a seshy session"
    return 1
  fi

  if [[ ${ZMX_SESSION:-} == "${ZMX_SESSION_PREFIX:-}${session}" ]]; then
    _seshy_debug "already attached to $ZMX_SESSION"
    return 0
  fi

  zmx attach "$session"
}

function sl() {
  _seshy_names
}

function si() {
  local session
  session=$(_seshy_names | fzf --height 40% --reverse --prompt "session> ") || return
  if [[ -z $session ]]; then
    _seshy_debug "no session selected"
    return 0
  fi
  s "$session"
}

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

