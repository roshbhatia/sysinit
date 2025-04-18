#!/usr/bin/env zsh
# shellcheck disable=all
_evalcache /opt/homebrew/bin/brew shellenv
_evalcache atuin init zsh --disable-up-arrow
_evalcache kubectl completion zsh
_evalcache docker completion zsh
_evalcache direnv hook zsh
_evalcache gh copilot alias -- zsh

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules'
export FZF_DEFAULT_OPTS="$(cat << 'EOF'
--preview-window=right:60%:wrap:border-rounded
--height=80%
--layout=reverse
--border=rounded
--margin=1
--padding=1
--info=inline-right
--prompt='❯ '
--pointer='▶'
--marker='✓'
--scrollbar='█'
--color=border:-1,fg:-1,bg:-1,hl:6,fg+:12,bg+:-1,hl+:12,info:7
--color=prompt:1,pointer:5,marker:2,spinner:5,header:4
--preview='([[ -f {} ]] && (([[ {} =~ \.md$ ]] && glow -s dark {}) || ([[ {} =~ \.json$ ]] && jq -C . {}) || ([[ {} =~ \.(js|jsx|ts|tsx|html|css|yml|yaml|toml|nix|sh|zsh|bash|fish)$ ]] && bat --color=always --style=numbers,header {}) || ([[ {} =~ \.(jpg|jpeg|png|gif)$ ]] && (kitten icat {} 2>/dev/null || imgcat {} 2>/dev/null || echo "Image preview not available")) || (bat --color=always --style=numbers,header {} || cat {}))) || ([[ -d {} ]] && eza -T --color=always --icons --git-ignore --git {} | head -200) || echo {}'
--bind='ctrl-/:toggle-preview'
--bind='ctrl-s:toggle-sort'
--bind='ctrl-space:toggle-preview-wrap'
--bind='tab:half-page-down'
--bind='btab:half-page-up'
--bind='ctrl-y:preview-up'
--bind='ctrl-e:preview-down'
--bind='?:toggle-preview'
--bind='alt-w:toggle-preview-wrap'
--bind='ctrl-u:clear-query'
--bind='resize:refresh-preview'
EOF
)"

export ENHANCD_FILTER="fzf --ansi --preview 'eza -al --tree --level 1 --group-directories-first --git-ignore --header --git --no-user --no-time --no-filesize --no-permissions {}' --preview-window=right:40%:wrap:border-rounded --height=35% --layout=reverse --border=rounded --margin=1 --padding=1 --info=inline-right --prompt='❯ ' --pointer='▶' --marker='✓' --scrollbar='█' --bind='ctrl-/:toggle-preview' --bind='ctrl-r:refresh-preview'"
export ENHANCD_ENABLE_DOUBLE_DOT=false
export ENHANCD_ENABLE_HOME=false

# fzf-tab configuration
zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:*' fzf-min-height 50
zstyle ':fzf-tab:*' fzf-pad 4

# Use the same colors as fzf default
zstyle ':fzf-tab:*' fzf-flags --color=border:-1,fg:-1,bg:-1,hl:6,fg+:12,bg+:-1,hl+:12,info:7

# Show file previews for file/dir completions
zstyle ':fzf-tab:complete:ls:*' fzf-preview 'eza -1 --color=always --icons --git-ignore --git $realpath'
zstyle ':fzf-tab:complete:cp:*' fzf-preview 'eza -1 --color=always --icons --git-ignore --git $realpath'
zstyle ':fzf-tab:complete:mv:*' fzf-preview 'eza -1 --color=always --icons --git-ignore --git $realpath'
zstyle ':fzf-tab:complete:rm:*' fzf-preview 'eza -1 --color=always --icons --git-ignore --git $realpath'

# Use enhancd fzf instead
zstyle ':fzf-tab:complete:cd:*' disabled-on any

# Preview content for text files
zstyle ':fzf-tab:complete:cat:*' fzf-preview 'bat --color=always --style=numbers,header {}'
zstyle ':fzf-tab:complete:vim:*' fzf-preview 'bat --color=always --style=numbers,header {}'
zstyle ':fzf-tab:complete:nvim:*' fzf-preview 'bat --color=always --style=numbers,header {}'

# Show systemd unit status
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'

# Environment variables
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
fzf-preview 'echo ${(P)word}'

# Git preview support
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview \
'git diff $word | delta'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview \
'git log --color=always $word'
zstyle ':fzf-tab:complete:git-help:*' fzf-preview \
'git help $word | bat --color=always --language=man'
zstyle ':fzf-tab:complete:git-show:*' fzf-preview \
'case "$group" in
    "commit tag") git show --color=always $word ;;
    *) git show --color=always $word | delta ;;
esac'
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview \
'case "$group" in
    "modified file") git diff $word | delta ;;
    "remote branch") git log --color=always $word ;;
    *) git log --color=always $word ;;
esac'

# General settings
zstyle ':fzf-tab:*' default-color $'\033[37m'
zstyle ':fzf-tab:*' show-group full
zstyle ':fzf-tab:*' prefix ''
zstyle ':fzf-tab:*' single-group color header
zstyle ':fzf-tab:*' switch-group 'alt-p' 'alt-n'

# Completion configuration
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zcompcache"
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu no
zstyle ':completion:*' fzf-preview 'echo ${(P)word}'

autoload -Uz compinit
if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
compinit
else
compinit -C
fi