#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/zsh/core/completions.sh (begin)

enable-fzf-tab
zvm_after_init_commands+="_evalcache atuin init zsh --disable-up-arrow"
zvm_after_init_commands+="_evalcache direnv hook zsh"
zvm_after_init_commands+="_evalcache gh copilot alias -- zsh"
zvm_after_init_commands+="_evalcache kubectl completion zsh"
zvm_after_init_commands+="_evalcache docker completion zsh"
zvm_after_init_commands+="_evalcache task --completion zsh"
zvm_after_init_commands+="_evalcache zoxide init zsh"

function z() {
	local dir
	dir=$(zoxide query "$@") && pushd "$dir"
}

# modules/darwin/home/zsh/core/completions.sh (end)

