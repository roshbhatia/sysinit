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

# Mail
unset MAILCHECK

# Locale settings
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

autoload -Uz compinit
compinit

# Zsh plugins
export ZSH_CUSTOM=$HOME/.zshcustom # @install-gen darwin::* mkdir -p $HOME/.zshcustom
export ZSH_CUSTOM_PLUGINS=$ZSH_CUSTOM/plugins

# Inherit iTerm colors for fzf
export FZF_DEFAULT_OPTS='
  --color=fg:-1,bg:-1,hl:6,fg+:15,bg+:0,hl+:6
  --color=info:2,prompt:2,spinner:2,pointer:2,marker:1
'
source $ZSH_CUSTOM_PLUGINS/fzf-tab/fzf-tab.zsh # @install-gen darwin::* git clone https://github.com/Aloxaf/fzf-tab $ZSH_CUSTOM_PLUGINS/fzf-tab
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh # @install-gen darwin::* brew install zsh-syntax-highlighting
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh # @install-gen darwin::* brew install zsh-autosuggestions

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

# word navigation
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
eval "$(direnv hook zsh)"

# Git configuration
git config --global alias.short-log 'log --pretty=format:"%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]" --decorate --date=short'
git config --global alias.latest-commit-sha 'rev-parse --short HEAD'
git config --global alias.branches '!git --no-pager branch -a'
git config --global core.editor "code --wait"

# Terraform
alias tf=terraform # @install-gen darwin::* brew install tfenv && tfenv install latest

# Node tooling
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# Python
export PATH="/usr/local/opt/cython/bin:$PATH"

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Ruby
export PATH="$HOME/.rvm/bin:$PATH"

# Rust
. "$HOME/.cargo/env"

# 1Password
eval "$(op completion zsh)"; compdef _op op

# Docker
eval "$(docker completion zsh)"

# GoEnv configuration
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"
export PATH="$GOROOT/bin:$PATH"
export PATH="$PATH:$GOPATH/bin"

# Kubernetes configuration
source <(kubectl completion zsh)
[[ ! -f ~/.kubecm ]] || source ~/.kubecm
export PATH="$HOME/.krew/bin:$PATH"
[ -f ~/.kubectl_aliases ] && source ~/.kubectl_aliases
alias kubectl=kubecolor

# Various editors
alias vim="nvim"
export EDITOR="code -w"

# Atuin
. "$HOME/.atuin/bin/env"
eval "$(atuin init zsh --disable-up-arrow)"

# Cod
eval "$(cod init $$ zsh)" # @install-gen darwin::* go install github.com/dim-an/cod@latest

# GH Cli
eval "$(gh completion -s zsh)" # @install-gen darwin::* brew install gh

# Extra configuration
[ -f ~/.zshextras ] && source ~/.zshextras
alias l="ls -l"

# Startup commands
export MACCHINA_THEME=${MACCHINA_THEME:-"rosh"}
macchina --theme $MACCHINA_THEME # @install-gen darwin::* brew install macchina
eval "$(starship init zsh)"  # @install-gen darwin::* brew install starship
