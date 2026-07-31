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

# `sy delete` gate.
#
# seshy runs its `preDelete` hook advisorily: a non-zero exit logs a warning and
# the deletion proceeds anyway, with or without `--force`. Verified against the
# installed binary. The hook is therefore where the report is PRINTED, and this
# wrapper is where it is ENFORCED.
#
# Only `delete`/`rm`/`remove` are intercepted; every other subcommand passes
# straight through, so this stays a gate and not a reimplementation of `sy`.
sy() {
  local sub=$1

  case $sub in
    delete | rm | remove) ;;
    *)
      command sy "$@"
      return $?
      ;;
  esac

  # `--force` is the documented escape. Honor it without running the report.
  local arg
  for arg in "$@"; do
    case $arg in
      -f | --force)
        command sy "$@"
        return $?
        ;;
    esac
  done

  # Resolve the session name: the first argument after the subcommand that is
  # not a flag. Without one, seshy picks interactively and this wrapper has
  # nothing to check, so it defers.
  local name=""
  shift
  for arg in "$@"; do
    case $arg in
      -*) ;;
      *)
        name=$arg
        break
        ;;
    esac
  done
  if [[ -z $name ]]; then
    command sy "$sub" "$@"
    return $?
  fi

  # Resolve the session directory. `sy path` is tried first, but it is not
  # relied on: it returned empty when called from inside this function during
  # testing, and a gate that silently defers is no gate. The fallback is the
  # `sessionsDir` this repository configures in seshy/config.yaml.
  # NOT named `path`: in zsh `path` is a special array tied to $PATH, so a
  # `local path` inside a function replaces PATH for that scope and every
  # command in it becomes unfindable. This cost a debugging round.
  local session_dir
  session_dir=$(command sy path "$name" 2> /dev/null)
  if [[ -z $session_dir || ! -d $session_dir ]]; then
    session_dir="$HOME/.local/state/seshy/sessions/$name"
  fi
  if [[ ! -d $session_dir ]]; then
    command sy "$sub" "$@"
    return $?
  fi

  if command -v agent-review > /dev/null 2>&1; then
    SESHY_SESSION=$name agent-review "$session_dir"
    local rc=$?
    if (( rc == 1 )); then
      _seshy_err "refusing to delete an unfinished session. Use 'sy delete --force $name' to delete anyway."
      return 1
    fi
    # rc 2 means the check could not run. Permissive on purpose: a readiness
    # check that fails must never make a session undeletable.
    (( rc == 2 )) && _seshy_err "readiness check could not run; continuing."
  fi

  command sy "$sub" "$@"
}
