#!/usr/bin/env zsh
# shellcheck disable=all
zvm_after_init_commands+="_evalcache atuin init zsh --disable-up-arrow"
zvm_after_init_commands+="_evalcache kubectl completion zsh"
zvm_after_init_commands+="_evalcache docker completion zsh"
zvm_after_init_commands+="_evalcache task --completion zsh"
zvm_after_init_commands+="complete -C '/etc/profiles/per-user/$USER/bin/aws_completer' aws"
zvm_after_init_commands+="_evalcache zoxide init zsh"
zvm_after_init_commands+="_evalcache gh copilot alias -- zsh"
zvm_after_init_commands+="_evalcache uv generate-shell-completion zsh"
zvm_after_init_commands+=$'\nfunction z() { local dir; dir=$(zoxide query "$@"); pushd "$dir"; }'
zvm_after_init_commands+='[[ -s "/usr/local/etc/grc.zsh" ]] && source /usr/local/etc/grc.zsh'
zvm_after_init_commands+="enable-fzf-tab"

# Load cursor-agent integration after zsh-vi-mode is initialized
# This must be done in a zvm_after_init function to ensure proper key binding
function zvm_after_init() {
  eval "$($HOME/.local/bin/cursor-agent shell-integration zsh)"
}
