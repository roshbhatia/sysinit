#!/usr/bin/env zsh
# shellcheck disable=all

# Wrap zoxide z and zi to use pushd instead of cd
__zoxide_z_pushd() {
  __zoxide_doctor
  if [[ $# -eq 0 ]]; then
    pushd ~ > /dev/null
  elif [[ $# -eq 1 ]] && { [[ -d $1 ]] || [[ $1 == '-' ]] || [[ $1 =~ ^[-+][0-9]$ ]]; }; then
    pushd "$1" > /dev/null
  elif [[ $# -eq 2 ]] && [[ $1 == "--" ]]; then
    pushd "$2" > /dev/null
  else
    \builtin local result
    result="$(\command zoxide query --exclude "$(__zoxide_pwd)" -- "$@")" && pushd "${result}" > /dev/null
  fi
}

__zoxide_zi_pushd() {
  __zoxide_doctor
  \builtin local result
  result="$(\command zoxide query --interactive -- "$@")" && pushd "${result}" > /dev/null
}

__setup_completions() {
  _evalcache atuin init zsh --disable-up-arrow
  _evalcache task --completion zsh
  _evalcache zoxide init zsh

  # Override zoxide default z/zi with pushd versions
  z() {
    __zoxide_z_pushd "$@"
  }
  zi() {
    __zoxide_zi_pushd "$@"
  }

  _evalcache uv generate-shell-completion zsh
  _evalcache nix-your-shell zsh

  _evalcache kubecolor completion zsh
  alias k="kubecolor"
  alias kubectl="kubecolor"
  compdef k=_kubectl

  enable-fzf-tab
}

zvm_after_init_commands+=(__setup_completions)
