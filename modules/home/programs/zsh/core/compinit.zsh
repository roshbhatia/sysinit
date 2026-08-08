#!/usr/bin/env zsh
# shellcheck disable=all

mkdir -p "$ZSH_CACHE_DIR"
autoload -Uz compinit
compinit -C -d "$ZSH_CACHE_DIR/zcompdump/.zcompdump"

setopt globdots

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR/zcompcache"
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu no

zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:git-checkout:*' sort false

zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' fzf-pad 4
zstyle ':fzf-tab:*' single-group color header
zstyle ':fzf-tab:*' show-group full
zstyle ':fzf-tab:*' fzf-flags --gutter=" " --preview-window=right:50%:wrap
zstyle ':fzf-tab:*' query-string ""
zstyle ':fzf-tab:*' continuous-trigger "/"
zstyle ':fzf-tab:*' fzf-bindings "tab:down" "btab:up" "enter:accept"

zstyle ':fzf-tab:complete:(bat|cat|cd|chafa|eza|ls|nvim|v|vi|vim):*' \
  fzf-preview 'fzf-preview "${realpath:-$word}"'
