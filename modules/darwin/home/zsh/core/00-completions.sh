#!/usr/bin/env zsh
# shellcheck disable=all

# ---------- FZF General Configuration ----------
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules'

# Simplified FZF options to avoid quoting issues
export FZF_DEFAULT_OPTS='--preview-window=right:60%:wrap:border-rounded --height=80% --layout=reverse --border=rounded --margin=1 --padding=1 --info=inline-right --prompt="❯ " --pointer="▶" --marker="✓" --scrollbar="█" --color=border:-1,fg:-1,bg:-1,hl:6,fg+:12,bg+:-1,hl+:12,info:7 --color=prompt:1,pointer:5,marker:2,spinner:5,header:4 --bind="ctrl-/:toggle-preview" --bind="ctrl-s:toggle-sort" --bind="ctrl-space:toggle-preview-wrap" --bind="tab:half-page-down" --bind="btab:half-page-up" --bind="ctrl-y:preview-up" --bind="ctrl-e:preview-down" --bind="?:toggle-preview" --bind="alt-w:toggle-preview-wrap" --bind="ctrl-u:clear-query" --bind="resize:refresh-preview"'

# Simplified ENHANCD configuration
export ENHANCD_FILTER='fzf --ansi --preview "eza -al --tree --level 1 --group-directories-first --git-ignore --header --git --no-user --no-time --no-filesize --no-permissions {}" --preview-window=right:40%:wrap:border-rounded'
export ENHANCD_ENABLE_DOUBLE_DOT=false
export ENHANCD_ENABLE_HOME=false

# ---------- ZSH-Autosuggest Configuration ----------
# Configure before loading completions
export ZSH_AUTOSUGGEST_USE_ASYNC=1
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1
export ZSH_AUTOSUGGEST_STRATEGY=(completion history)
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#8FBBE6,bold,underline"
for dir in "${fpath[@]}"; do
  if [[ -f "$dir/zsh-autosuggestions.plugin.zsh" ]]; then
    source "$dir/zsh-autosuggestions.plugin.zsh"
    break
  fi
done

# ---------- General Completion Settings ----------
# Initialize completions first
autoload -Uz compinit
if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
  compinit
else
  compinit -C
fi

# Base completion configuration
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zcompcache"
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# ---------- FZF-TAB Configuration ----------
# Basic settings
zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:*' fzf-min-height 50
zstyle ':fzf-tab:*' fzf-pad 4
zstyle ':fzf-tab:*' default-color $'\033[37m'
zstyle ':fzf-tab:*' show-group full
zstyle ':fzf-tab:*' prefix ''
zstyle ':fzf-tab:*' single-group color header
zstyle ':fzf-tab:*' switch-group 'alt-p' 'alt-n'

# Color settings
zstyle ':fzf-tab:*' fzf-flags --color=border:-1,fg:-1,bg:-1,hl:6,fg+:12,bg+:-1,hl+:12,info:7

# Simple file previews - using minimal set first to avoid errors
zstyle ':fzf-tab:complete:ls:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:cd:*' disabled-on any