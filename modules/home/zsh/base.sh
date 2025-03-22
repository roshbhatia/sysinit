# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
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
export ZSH_DISABLE_COMPFIX="true"

# Key bindings
bindkey "^[[1;7C" forward-word
bindkey "^[[1;7D" backward-word
bindkey "^[[1;7B" beginning-of-line
bindkey "^[[1;7A" end-of-line

if [ -f "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  
  if command -v kubectl &> /dev/null; then
    _evalcache kubectl completion zsh
  fi
  
  if command -v docker &> /dev/null; then
    _evalcache docker completion zsh
  fi
  
  if command -v stern &> /dev/null; then
    _evalcache stern --completion zsh
  fi
  
  if command -v gh &> /dev/null; then
    _evalcache gh completion -s zsh
  fi
  
  # Source other plugins
  if [ -f "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  fi
  
  if [ -f "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  fi
fi

# Ensure plugin directories exist
export ZSH_CUSTOM="$HOME/.config/zsh"
export ZSH_CUSTOM_PLUGINS="$ZSH_CUSTOM/plugins"

# Create plugin directories if they don't exist
mkdir -p $ZSH_CUSTOM_PLUGINS

# Source plugins if they exist
if [ -f "$ZSH_CUSTOM_PLUGINS/evalcache/evalcache.plugin.zsh" ]; then
    source "$ZSH_CUSTOM_PLUGINS/evalcache/evalcache.plugin.zsh"
fi

if [ -f "$ZSH_CUSTOM_PLUGINS/fzf-tab/fzf-tab.zsh" ]; then
    source "$ZSH_CUSTOM_PLUGINS/fzf-tab/fzf-tab.zsh"
fi

# Initialize completions before aliases
autoload -Uz compinit
# shellcheck disable=SC1036
# shellcheck disable=SC1058
# shellcheck disable=SC1072
for dump in $HOME/.zcompdump(N.mh+24); do
  compinit -Ci
done
compinit -Ci

# Load all utility modules from extras directory
for module in $HOME/.config/zsh/extras/*.sh; do
  if [[ -f "$module" ]]; then
    source "$module"
  fi
done

# Rest of tool initializations
if command -v direnv &> /dev/null; then
  _evalcache direnv hook zsh
fi

if command -v gh &> /dev/null; then
  _evalcache gh copilot alias -- zsh
fi

if command -v starship &> /dev/null; then
  _evalcache starship init zsh
fi

if command -v atuin &> /dev/null; then
  _evalcache atuin init zsh
fi

# Fzf
export FZF_DEFAULT_OPTS="
  --height 8
  --layout=reverse
  --border
  --inline-info
"

# Source path configurations
[ -f "$HOME/.config/zsh/paths.sh" ] && source "$HOME/.config/zsh/paths.sh"

# GitHub username functions
function ghwhoami() {
  if command -v gh &> /dev/null; then
    gh api user --jq '.login' 2>/dev/null || echo 'Not logged in'
  else
    echo 'gh not installed'
  fi
}

function update_github_user() {
  export GITHUB_USER=$(ghwhoami)
}

# Update GitHub user on shell startup
update_github_user

# Disable ctrl+s to freeze terminal
stty stop undef

# Force rebuild of completion files
autoload -Uz compinit
compinit -u

# Kubernetes completion
if command -v kubecolor &> /dev/null; then
  compdef kubecolor=kubectl
fi

if command -v kubectl &> /dev/null; then
  compdef k=kubectl
fi

# Source extras if they exist
[ -f ~/.zshenv ] && source ~/.zshenv
[ -f ~/.zshextras ] && source ~/.zshextras
[ -f ~/.zshutils ] && source ~/.zshutils

# Run macchina in WezTerm's main pane
if [ "$WEZTERM_PANE" = "0" ]; then
  if [ -n "$MACCHINA_THEME" ]; then
    macchina --theme "$MACCHINA_THEME"
  else
    macchina --theme rosh
  fi
fi
