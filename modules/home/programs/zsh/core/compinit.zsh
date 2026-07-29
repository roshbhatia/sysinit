#!/usr/bin/env zsh
# shellcheck disable=all
# Completion init and styling. Lives in a fragment file rather than inline in
# default.nix so `checks.zsh-fragments-parse` actually sees it: the check globs
# *.zsh, and a Nix string literal is invisible to it.
#
# ZSH_CACHE_DIR is set by default.nix immediately before this is sourced. It is
# the one value that has to come from Nix.

mkdir -p "$ZSH_CACHE_DIR"
autoload -Uz compinit
compinit -C -d "$ZSH_CACHE_DIR/zcompdump/.zcompdump"

# Include dotfiles in tab completion (fzf-tab inherits from zsh's
# underlying completion). Without globdots, `cd <tab>` and similar
# only show non-hidden entries; with it, dotfiles appear too.
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
