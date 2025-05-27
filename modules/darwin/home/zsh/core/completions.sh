#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/zsh/core/completions.sh (begin)
mkdir -p "${XDG_DATA_HOME}/zsh/zcompdump"
autoload -Uz compinit
if [[ -n ${XDG_DATA_HOME}/zsh/zcompdump/.zcompdump(#qN.mh+24) ]]; then
compinit -d "${XDG_DATA_HOME}/zsh/zcompdump/.zcompdump";
else
compinit -C -d "${XDG_DATA_HOME}/zsh/zcompdump/.zcompdump";
fi

zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu no
zstyle ':completion:*:complete:*' use-cache on
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --icons=always -1 -a $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --icons=always -1 -a $realpath'
zstyle ':fzf-tab:complete:cat:*' fzf-preview 'bat --color=always $realpath'
zstyle ':fzf-tab:complete:bat:*' fzf-preview 'bat --color=always $realpath'
zstyle ':fzf-tab:complete:nvim:*' fzf-preview 'bat --color=always $realpath'
zstyle ':fzf-tab:*' fzf-flags ${SYSINIT_FZF_OPTS} --color=fg:1,fg+:2 --bind=tab:accept

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

