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

# Source pre-path
source $HOME/.config/zsh/conf.d/path.pre.zsh

# Zellij configuration
if [[ -z "$ZELLIJ" ]]; then
    if command -v zellij >/dev/null 2>&1; then
        if [[ -z "$ZELLIJ_AUTO_START" && ! "$TERM_PROGRAM" == "vscode" ]]; then
            export ZELLIJ_AUTO_START=true
            exec zellij
        fi
    else
        echo "Zellij not found. Please install it first."
    fi
fi

export EDITOR="code --wait"

# Load essential plugins and completions first
eval "$(/opt/homebrew/bin/brew shellenv)"

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
for dump in $HOME/.zcompdump(N.mh+24); do
  compinit
done
compinit -Ci

# Load completions first
_evalcache kubectl completion zsh
_evalcache docker completion zsh
_evalcache stern --completion zsh
_evalcache gh completion -s zsh

# Source configurations after completions are loaded
for conf in $HOME/.config/zsh/conf.d/*.zsh; do
    source $conf
done

# Source other plugins
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Rest of tool initializations
_evalcache direnv hook zsh
_evalcache gh copilot alias -- zsh
_evalcache starship init zsh

# Source extras if they exist
[ -f ~/.zshenv ] && source ~/.zshenv
[ -f ~/.zshextras ] && source ~/.zshextras
[ -f ~/.zshutils ] && source ~/.zshutils

# Key bindings
bindkey "^[[1;7C" forward-word
bindkey "^[[1;7D" backward-word
bindkey "^[[1;7B" beginning-of-line
bindkey "^[[1;7A" end-of-line
