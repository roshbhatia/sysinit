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
[ -f "$XDG_CONFIG_HOME/zsh/paths.sh" ] && source "$XDG_CONFIG_HOME/zsh/paths.sh"

unset MAILCHECK
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export ZSH_DISABLE_COMPFIX="true"

# Zsh autosuggestions configuration
export ZSH_AUTOSUGGEST_USE_ASYNC=1
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=50
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#B4A7D6,bold"
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# Add key binding to accept suggestion and execute immediately
bindkey '^X' autosuggest-execute

# Set up completion paths
fpath=(/opt/homebrew/share/zsh/site-functions $fpath)

# Initialize completions before anything else
autoload -Uz compinit
zstyle ':completion:*' menu select
for dump in $HOME/.zcompdump(N.mh+24); do
  compinit -Ci
done
compinit -Ci

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

# Smart notifications for long-running commands
function notify_when_done() {
  local cmd=$1
  local start_time=$2
  local end_time=$(date +%s)
  local elapsed=$((end_time - start_time))
  
  if [[ $elapsed -gt 10 ]]; then
    if command -v terminal-notifier &> /dev/null; then
      terminal-notifier -title "Task Complete" -message "Finished: $cmd (took ${elapsed}s)" -sound default
    fi
  fi
}

function preexec_notify() {
  cmd_start_time=$(date +%s)
  cmd_name=$1
}

function precmd_notify() {
  if [[ -n $cmd_start_time ]]; then
    notify_when_done "$cmd_name" $cmd_start_time
    unset cmd_start_time
  fi
}

# Register hooks for title and notifications
precmd_functions+=(precmd_notify)
preexec_functions+=(preexec_notify)

if [ -f "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"

  if command -v fzf &> /dev/null; then
    source <(fzf --zsh)
  fi

  # Initialize atuin with evalcache
  if command -v atuin &> /dev/null; then
    _evalcache atuin init zsh --disable-up-arrow
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

# Function to list directories with eza
function _eza_ls_for_completion() {
  # Check if eza is installed
  if command -v eza &> /dev/null; then
    eza --icons --git-ignore --color=always -1 "$@"
  else
    # Fallback to ls if eza is not available
    ls -la "$@"
  fi
}

# Set up eza for file/directory listing during completion
zstyle ':completion:*' file-list-rows-first true
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Use the function for directory listings in completions
zstyle ':completion:*' file-list-display _eza_ls_for_completion

# Configure list-dirs-first for better organization
zstyle ':completion:*' list-dirs-first true

# Improve the appearance of completion menus
zstyle ':completion:*:descriptions' format '%F{yellow}%d%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:default' list-prompt '%S%M matches%s'

# Source logging library first (ensure it's available to all scripts)
[ -f "$XDG_CONFIG_HOME/zsh/loglib.sh" ] && source "$XDG_CONFIG_HOME/zsh/loglib.sh"

# Load loglib in extras first if it exists
if [[ -f "$XDG_CONFIG_HOME/zsh/extras/loglib.sh" ]]; then
  source "$XDG_CONFIG_HOME/zsh/extras/loglib.sh"
fi

# Then, source zshextras
[ -f ~/.zshextras ] && source ~/.zshextras

# Then load all other utility modules from extras directory
for module in $XDG_CONFIG_HOME/zsh/extras/*.sh; do
  if [[ -f "$module" && "$module" != "$XDG_CONFIG_HOME/zsh/extras/loglib.sh" ]]; then
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