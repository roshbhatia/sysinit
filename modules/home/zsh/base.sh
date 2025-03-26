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

# General settings
unset MAILCHECK
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export ZSH_DISABLE_COMPFIX="true"

# Zsh autosuggestions configuration
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#B4A7D6"
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
export ZSH_AUTOSUGGEST_USE_ASYNC=1
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# Set up completion paths
fpath=(/opt/homebrew/share/zsh/site-functions $fpath)

# Initialize completions before anything else
autoload -Uz compinit
zstyle ':completion:*' menu select
for dump in $HOME/.zcompdump(N.mh+24); do
  compinit -Ci
done
compinit -Ci

if [ -f "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"

  if command -v fzf &> /dev/null; then
    source <(fzf --zsh)
  fi

  if command -v atuin &> /dev/null; then
    eval "$(atuin init zsh --disable-up-arrow)"
  fi
  
  # Then load other completions
  if command -v kubectl &> /dev/null; then
    source <(kubectl completion zsh)
  fi
  
  if command -v docker &> /dev/null; then
    source <(docker completion zsh)
  fi
  
  if command -v stern &> /dev/null; then
    source <(stern --completion zsh)
  fi
  
  if command -v gh &> /dev/null; then
    source <(gh completion -s zsh)
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

# Source logging library first (ensure it's available to all scripts)
[ -f "$HOME/.config/zsh/loglib.sh" ] && source "$HOME/.config/zsh/loglib.sh"

# Load loglib in extras first if it exists
if [[ -f "$HOME/.config/zsh/extras/loglib.sh" ]]; then
  source "$HOME/.config/zsh/extras/loglib.sh"
fi

# Then, source zshextras
[ -f ~/.zshextras ] && source ~/.zshextras

# Then load all other utility modules from extras directory
for module in $HOME/.config/zsh/extras/*.sh; do
  if [[ -f "$module" && "$module" != "$HOME/.config/zsh/extras/loglib.sh" ]]; then
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

# Fzf
export FZF_DEFAULT_OPTS="
  --height 8
  --layout=reverse
  --border
  --inline-info
  --bind 'ctrl-r:refresh-preview'
"

# Source path configurations
[ -f "$HOME/.config/zsh/paths.sh" ] && source "$HOME/.config/zsh/paths.sh"

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
[ -f ~/.zshutils ] && source ~/.zshutils

# Run macchina in WezTerm's main pane
if [ "$WEZTERM_PANE" = "0" ]; then
  if [ -n "$MACCHINA_THEME" ]; then
    macchina --theme "$MACCHINA_THEME"
  else
    macchina --theme rosh
  fi
fi
