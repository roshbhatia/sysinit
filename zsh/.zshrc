# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"
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

# General settings
unset MAILCHECK

export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export XDG_CONFIG_HOME=$HOME/.config

autoload -Uz compinit
for dump in $HOME/.zcompdump(N.mh+24); do
  compinit
done
compinit -Ci

# Zsh plugins configuration
export ZSH_CUSTOM=$HOME/.zshcustom
export ZSH_CUSTOM_PLUGINS=$ZSH_CUSTOM/plugins

export FZF_DEFAULT_OPTS='
  --layout=reverse
  --cycle
  --tmux
  --multi
  --delimiter :
  --ansi
  --preview-window "right,50%,border-left,+{2}+3/3,~3"
  --height "100%"
'

# Homebrew configuration
eval "$(/opt/homebrew/bin/brew shellenv)"
export CPATH="$(brew --prefix)/include:$CPATH"
export LIBRARY_PATH="$(brew --prefix)/lib:$LIBRARY_PATH"

# Load Zsh plugins
source $ZSH_CUSTOM_PLUGINS/evalcache/evalcache.plugin.zsh
_evalcache fzf --zsh
source $ZSH_CUSTOM_PLUGINS/fzf-tab/fzf-tab.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Zsh completion styles
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*' complete-options true
zstyle ':completion:*' file-list all
zstyle ':completion:*' menu no
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' verbose yes
zstyle ':fzf-tab:*' use-fzf-default-opts yes

# Git configuration
git config --global alias.short-log 'log --pretty=format:"%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]" --decorate --date=short'
git config --global alias.current-commit-sha 'rev-parse --short HEAD'
git config --global alias.current-branch 'rev-parse --abbrev-ref HEAD'
git config --global alias.branches '!git --no-pager branch -a'
git config --global core.editor "code --wait"

# Terraform alias
alias tf=terraform

# Node.js tooling
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# Python configuration
export PATH="/usr/local/opt/cython/bin:$PATH"

# Ruby configuration
export PATH="$HOME/.rvm/bin:$PATH"

# Rust configuration
. "$HOME/.cargo/env"
export PATH="$HOME/.cargo/bin:$PATH"

# Docker completion
_evalcache docker completion zsh

# GoEnv configuration
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
_evalcache goenv init -
export PATH="$GOROOT/bin:$PATH"
export PATH="$PATH:$GOPATH/bin"
export PATH=$PATH:$(go env GOPATH)/bin

# Kubernetes configuration
[[ ! -f ~/.kubecm ]] || source ~/.kubecm
export PATH="$HOME/.krew/bin:$PATH"

_evalcache kubectl completion zsh
_evalcache stern --completion zsh

alias kubectl=kubecolor
compdef kubecolor=kubectl
alias k=kubectl
compdef k=kubectl

# Editors configuration
alias vim="nvim"
export EDITOR="code --wait"

# GitHub CLI completion
_evalcache gh completion -s zsh
_evalcache gh copilot alias -- zsh

# Atuin configuration
. "$HOME/.atuin/bin/env"
_evalcache atuin init zsh --disable-up-arrow

# Navigation aliases
alias l="ls -l"
alias ..="cd .."
alias ...="cd ../.."

# Key bindings for navigation
bindkey "^[[1;7C" forward-word
bindkey "^[[1;7D" backward-word
bindkey "^[[1;7B" beginning-of-line
bindkey "^[[1;7A" end-of-line

# Clear scrollback buffer function
function clear-scrollback-buffer {
  clear
  printf '\e[3J'
  zle .reset-prompt && zle -R
}

zle -N clear-scrollback-buffer
bindkey '^L' clear-scrollback-buffer

# Direnv configuration
_evalcache direnv hook zsh

# Yazi alias
alias y="yazi"

# Extras
source $HOME/github/roshbhatia/sysinit/utils/crepo.sh
source $HOME/github/roshbhatia/sysinit/utils/ghwhoami.sh
source $HOME/github/roshbhatia/sysinit/utils/kellog.sh
source $HOME/github/roshbhatia/sysinit/utils/kfzf.sh

[ -f ~/.zshextras ] && source ~/.zshextras

# Starship prompt initialization
_evalcache starship init zsh

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"
