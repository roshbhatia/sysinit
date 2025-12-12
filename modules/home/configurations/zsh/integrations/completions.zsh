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
  _evalcache docker completion zsh
  _evalcache task --completion zsh
  complete -C "/etc/profiles/per-user/$USER/bin/aws_completer" aws
  _evalcache zoxide init zsh

  # Override zoxide default z/zi with pushd versions
  z() {
    __zoxide_z_pushd "$@"
  }
  zi() {
    __zoxide_zi_pushd "$@"
  }

  _evalcache gh copilot alias -- zsh
  _evalcache uv generate-shell-completion zsh
  _evalcache command kubectl completion zsh

  # kubectl alias completions (aliases defined in shellAliases)
  compdef kubectl=kubectl
  compdef k=kubectl
  compdef kg=kubectl
  compdef kd=kubectl
  compdef ke=kubectl
  compdef ka=kubectl
  compdef kpf=kubectl
  compdef kdel=kubectl
  compdef klog=kubectl

  enable-fzf-tab
}

zvm_after_init_commands+=(__setup_completions)
