#!/usr/bin/env zsh
# shellcheck disable=all

zvm_after_init_commands+="_evalcache atuin init zsh --disable-up-arrow"
zvm_after_init_commands+="_evalcache kubectl completion zsh"
zvm_after_init_commands+="_evalcache docker completion zsh"
zvm_after_init_commands+="_evalcache task --completion zsh"
zvm_after_init_commands+="complete -C '/etc/profiles/per-user/$USER/bin/aws_completer' aws"
zvm_after_init_commands+=$'_evalcache zoxide init zsh'
# Override the zoxide shorthand to use pushd
zvm_after_init_commands+=$'\nfunction z() { local dir; dir=$(zoxide query "$@"); pushd "$dir"; }'

zvm_after_init_commands+="enable-fzf-tab"
