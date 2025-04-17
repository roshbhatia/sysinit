#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
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

export ENHANCD_FILTER="$(cat << 'EOF'
fzf --preview='([[ -d {} ]] && eza --tree --level 2 --color=always --icons --git-ignore --git --header --long --no-user --no-time --no-filesize {}) || echo {}' \
    --preview-window=right:60%:wrap:border-rounded \
    --height=80% \
    --reverse \
    --border=rounded \
    --margin=1 \
    --padding=1 \
    --info=inline-right \
    --ansi:fzy:peco
EOF
)"
