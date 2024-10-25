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

# general
unset MAILCHECK

export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export XDG_CONFIG_HOME=$HOME/.config

autoload -Uz compinit
for dump in $HOME/.zcompdump(N.mh+24); do
  compinit
done
compinit -Ci

# zsh plugins
export ZSH_CUSTOM=$HOME/.zshcustom
export ZSH_CUSTOM_PLUGINS=$ZSH_CUSTOM/plugins

# Inherit iTerm colors for fzf
export FZF_DEFAULT_OPTS='
  --color=fg:-1,bg:-1,hl:6,fg+:15,bg+:0,hl+:6
  --color=info:2,prompt:2,spinner:2,pointer:2,marker:1
  --layout=reverse
  --cycle
  --tmux
'

# iTerm
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh" || true

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

export CPATH="$(brew --prefix)/include:$CPATH"
export LIBRARY_PATH="$(brew --prefix)/lib:$LIBRARY_PATH"

# Zsh plugins
source $ZSH_CUSTOM_PLUGINS/evalcache/evalcache.plugin.zsh
source $ZSH_CUSTOM_PLUGINS/fzf-tab/fzf-tab.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*' complete-options true
zstyle ':completion:*' file-list all
zstyle ':completion:*' menu no
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' verbose yes
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'

# # Git configuration
(git config --global alias.short-log 'log --pretty=format:"%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]" --decorate --date=short' &>/dev/null &)
(git config --global alias.current-commit-sha 'rev-parse --short HEAD' &>/dev/null &)
(git config --global alias.current-branch 'rev-parse --abbrev-ref HEAD' &>/dev/null &)
(git config --global alias.branches '!git --no-pager branch -a' &>/dev/null &)
(git config --global core.editor "code --wait" &>/dev/null &)

# Terraform
alias tf=terraform

# Node tooling
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# Python
export PATH="/usr/local/opt/cython/bin:$PATH"

# Ruby
export PATH="$HOME/.rvm/bin:$PATH"

# Rust
. "$HOME/.cargo/env"
export PATH="$HOME/.cargo/bin:$PATH"

# Docker
_evalcache docker completion zsh

# GoEnv configuration
_evalcache goenv init -

# Kubernetes configuration
[[ ! -f ~/.kubecm ]] || source ~/.kubecm
export PATH="$HOME/.krew/bin:$PATH"

_evalcache kubectl completion zsh

alias kubectl=kubecolor
compdef kubecolor=kubectl

alias k=kubectl
compdef k=kubectl

# Editors
alias vim="nvim"
export EDITOR="code --wait"

# GH Cli
_evalcache gh completion -s zsh
_evalcache gh copilot alias -- zsh

# Atuin
. "$HOME/.atuin/bin/env"
_evalcache atuin init zsh --disable-up-arrow

# Navigation
alias l="ls -l"
alias ..="cd .."
alias ...="cd ../.."

bindkey "^[^[[C" forward-word
bindkey "^[^[[D" backward-word
bindkey "^[^[[B" beginning-of-line
bindkey "^[^[[A" end-of-line

function clear-scrollback-buffer {
  # clear screen
  clear
  # clear buffer
  printf '\e[3J'
  # .reset-prompt: bypass the zsh-syntax-highlighting wrapper
  # https://github.com/sorin-ionescu/prezto/issues/1026
  # https://github.com/zsh-users/zsh-autosuggestions/issues/107#issuecomment-183824034
  # -R: redisplay the prompt to avoid old prompts being eaten up
  # https://github.com/Powerlevel9k/powerlevel9k/pull/1176#discussion_r299303453
  zle .reset-prompt && zle -R
}

zle -N clear-scrollback-buffer
bindkey '^L' clear-scrollback-buffer

# Direnv
_evalcache direnv hook zsh

# Extras
[ -f ~/.zshextras ] && source ~/.zshextras

# Startup commands
export MACCHINA_THEME=${MACCHINA_THEME:-"rosh"}

# Run macchina only if the tab number in ITERM_SESSION_ID is 0
if [[ "$ITERM_SESSION_ID" =~ ^w[0-9]+t0p[0-9]+: ]]; then
  macchina --theme $MACCHINA_THEME
fi

_evalcache starship init zsh