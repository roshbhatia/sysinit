#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# sysinit.nix-shell::ignore
#       ___           ___           ___           ___           ___
#      /  /\         /  /\         /__/\         /  /\         /  /\
#     /  /::|       /  /:/_        \  \:\       /  /::\       /  /:/
#    /  /:/:|      /  /:/ /\        \__\:\     /  /:/\:\     /  /:/
#   /  /:/|:|__   /  /:/ /::\   ___ /  /::\   /  /:/~/:/    /  /:/  ___
#  /__/:/ |:| /\ /__/:/ /:/\:\ /__/\  /:/\:\ /__/:/ /:/___ /__/:/  /  /\
#  \__\/  |:|/:/ \  \:\/:/~/:/ \  \:\/:/__\/ \  \:\/:::::/ \  \:\ /  /:/
#      |  |:/:/   \  \::/ /:/   \  \::/       \  \::/~~~~   \  \:\  /:/
#      |  |::/     \__\/ /:/     \  \:\        \  \:\        \  \:\/:/
#      |  |:/        /__/:/       \  \:\        \  \:\        \  \::/
#      |__|/         \__\/         \__\/         \__\/         \__\/

export FZF_DEFAULT_OPTS="
  --preview-window=right:55%:wrap:border-rounded
  --height=60%
  --layout=reverse
  --border=rounded
  --info=inline-right
  --prompt='❯ '
  --pointer='▶'
  --marker='✓'
  --color=border:-1
  --color=fg:-1,bg:-1,hl:6
  --color=fg+:-1,bg+:-1,hl+:12
  --color=info:7,prompt:1,pointer:5
  --color=marker:2,spinner:5,header:4
  --preview='if [[ -f {} ]]; then case {} in *.md) glow -s dark {};; *.json) jq -C . {};; *.{js,jsx,ts,tsx,html,css,yml,yaml,toml,sh,zsh,bash}) bat --color=always --style=numbers,header {};; *.{jpg,jpeg,png,gif}) imgcat {} 2>/dev/null || echo \"Image preview not available\";; *) bat --color=always --style=numbers,header {} || cat {};; esac elif [[ -d {} ]]; then eza -T --color=always --icons --git-ignore --git {} | head -200 else echo {} fi'
  --bind 'ctrl-p:toggle-preview'
  --bind 'ctrl-s:toggle-sort'
  --bind 'ctrl-y:execute-silent(echo -n {} | pbcopy)'
  --bind 'ctrl-e:execute(${EDITOR:-nvim} {} < /dev/tty > /dev/tty)'
  --bind 'tab:half-page-down'
  --bind 'btab:half-page-up'
  --bind 'alt-j:preview-down'
  --bind 'alt-k:preview-up'
  --bind 'resize:refresh-preview'
"

export FZF_CTRL_R_OPTS="--height=60% --layout=reverse --border=rounded --preview-window=hidden"