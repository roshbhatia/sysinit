#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/zsh/core/completions.sh (begin)

zvm_after_init_commands+="_evalcache atuin init zsh --disable-up-arrow"
zvm_after_init_commands+="_evalcache kubectl completion zsh"
zvm_after_init_commands+="_evalcache docker completion zsh"
zvm_after_init_commands+="_evalcache task --completion zsh"
zvm_after_init_commands+="complete -C '/etc/profiles/per-user/$USER/bin/aws_completer' aws"
zvm_after_init_commands+=$'_evalcache zoxide init zsh'
# Override the zoxide shorthand to use pushd
zvm_after_init_commands+=$'\nfunction z() { local dir; dir=$(zoxide query "$@"); pushd "$dir"; }'

zvm_after_init_commands+="enable-fzf-tab"
# modules/darwin/home/zsh/core/completions.sh (end)

