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
zvm_after_init_commands+=$'\n_cursor_agent_wrapper() { _evalcache ~/.local/bin/cursor-agent shell-integration zsh; bindkey -M emacs "^I" fzf-tab-complete; bindkey -M viins "^I" fzf-tab-complete; }'
zvm_after_init_commands+="_cursor_agent_wrapper"
