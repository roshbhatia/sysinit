#!/usr/bin/env zsh
# shellcheck disable=all

mkdir -p "$ZSH_CACHE_DIR"

# nixpkgs ships a zsh completion per tool under the profile, and none of the 68
# on this machine was reachable: the profile's site-functions was absent from
# fpath, so `cat /et<TAB>` printed "_bat: function definition file not found"
# and the failing widget garbled the line.
#
# $USERNAME rather than a literal name: the two hosts use different accounts.
_zdump="$ZSH_CACHE_DIR/zcompdump/.zcompdump"
_zprofile="/etc/profiles/per-user/$USERNAME"
for _zsitefns in \
  "$HOME/.nix-profile/share/zsh/site-functions" \
  "$_zprofile/share/zsh/site-functions" \
  /run/current-system/sw/share/zsh/site-functions; do
  [[ -d $_zsitefns ]] && fpath=("$_zsitefns" $fpath)
done

# -C skips the scan for new completion files, which is the fast path and the
# reason a switch used to leave the dump stale. A new profile generation adds
# completions the dump cannot know about, so drop it when the profile is newer.
[[ -f $_zdump && -e $_zprofile && $_zdump -ot $_zprofile ]] && rm -f "$_zdump"

autoload -Uz compinit
compinit -C -d "$_zdump"
unset _zdump _zprofile _zsitefns

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
