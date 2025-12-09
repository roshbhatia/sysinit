#!/usr/bin/env zsh
# shellcheck disable=all

# Load completions after zsh-vi-mode initializes
zvm_after_init_commands+="_evalcache atuin init zsh --disable-up-arrow"
zvm_after_init_commands+="_evalcache docker completion zsh"
zvm_after_init_commands+="_evalcache task --completion zsh"
zvm_after_init_commands+="complete -C '/etc/profiles/per-user/$USER/bin/aws_completer' aws"
zvm_after_init_commands+="_evalcache zoxide init zsh"
zvm_after_init_commands+="_evalcache gh copilot alias -- zsh"
zvm_after_init_commands+="_evalcache uv generate-shell-completion zsh"
zvm_after_init_commands+=$'\nfunction z() { local dir; dir=$(zoxide query "$@"); pushd "$dir"; }'
zvm_after_init_commands+='[[ -s "/usr/local/etc/grc.zsh" ]] && source /usr/local/etc/grc.zsh'
zvm_after_init_commands+="enable-fzf-tab"

# kubectl completion - use real kubectl binary for completion generation
zvm_after_init_commands+=$'\nsource <(command kubectl completion zsh)	'
