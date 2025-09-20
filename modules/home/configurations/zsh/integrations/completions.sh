#!/usr/bin/env zsh
# shellcheck disable=all
zvm_after_init_commands+="_evalcache atuin init zsh --disable-up-arrow"
zvm_after_init_commands+="_evalcache kubectl completion zsh"
zvm_after_init_commands+="_evalcache docker completion zsh"
zvm_after_init_commands+="_evalcache task --completion zsh"
zvm_after_init_commands+="complete -C '/etc/profiles/per-user/$USER/bin/aws_completer' aws"
zvm_after_init_commands+="_evalcache zoxide init zsh"
zvm_after_init_commands+="_evalcache gh copilot alias -- zsh"
zvm_after_init_commands+='
_evalcache uv generate-shell-completion zsh

_uv_run_mod() {
  if [[ "$words[2]" == "run" && "$words[CURRENT]" != -* ]]; then
    _arguments ":filename:_files -g \".py\""
  else
    _uv "$@"
  fi
}
compdef _uv_run_mod uv
'

# Override the zoxide shorthand to use pushd
zvm_after_init_commands+=$'\nfunction z() { local dir; dir=$(zoxide query "$@"); pushd "$dir"; }'

zvm_after_init_commands+="enable-fzf-tab"
