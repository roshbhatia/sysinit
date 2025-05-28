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

# These need to be set prior to zoxide init
export _ZO_FZF_OPTS=" \
--preview-window=right:60%:wrap:border-rounded \
--height=80% \
--layout=reverse \
--border=rounded \
--margin=1 \
--padding=1 \
--info=inline-right \
--prompt='❯ ' \
--pointer='▶' \
--marker='✓' \
--scrollbar='||' \
--color=bg+:,bg:,spinner:#ebbcba,hl:#eb6f92 \
--color=fg:#e0def4,header:#eb6f92,info:#9ccfd8,pointer:#ebbcba \
--color=marker:#c4a7e7,fg+:#e0def4,prompt:#9ccfd8,hl+:#eb6f92 \
--color=selected-bg:#31748f \
--color=border:#2a273f,label:#e0def4 \
--bind='resize:refresh-preview'"
zvm_after_init_commands+="_evalcache zoxide init zsh"
zvm_after_init_commands+="function z() { local dir=\$(zoxide query \"\$@\") && pushd \"$dir\" }"
# modules/darwin/home/zsh/core/completions.sh (end)
