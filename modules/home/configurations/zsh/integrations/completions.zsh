#!/usr/bin/env zsh
# shellcheck disable=all

zvm_after_init_commands+=$'
_evalcache atuin init zsh --disable-up-arrow
_evalcache docker completion zsh
_evalcache task --completion zsh
complete -C "/etc/profiles/per-user/$USER/bin/aws_completer" aws
_evalcache zoxide init zsh
_evalcache gh copilot alias -- zsh
_evalcache uv generate-shell-completion zsh
_evalcache command kubectl completion zsh
enable-fzf-tab
'
