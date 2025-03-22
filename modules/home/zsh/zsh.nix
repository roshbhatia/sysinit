{ config, lib, pkgs, ... }:

{
  # Zsh configuration
  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;
    
    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
      share = true;
    };
    
    shellAliases = {
      # Navigation
      l = "eza --icons=always -1";
      ll = "eza --icons=always -1 -a";
      lt = "eza --icons=always -1 -a -T";
      ".." = "cd ..";
      "..." = "cd ../..";
      "~" = "cd ~";
      
      # Tools
      tf = "terraform";
      vim = "nvim";
      y = "yazi";
      
      # Kubernetes
      kubectl = "kubecolor";
      k = "kubectl";
    };
    
    plugins = [
      {
        name = "evalcache";
        src = pkgs.fetchFromGitHub {
          owner = "mroth";
          repo = "evalcache";
          rev = "v1.0.2"; # Use the latest stable release
          sha256 = "sha256-qzpnGTrLnq5mNaLlsjSA6VESA88XBdN3Ku/YIgLCb28=";
        };
        file = "evalcache.plugin.zsh";
      }
    ];
    
    initExtraFirst = ''
      # Ensure config directories exist
      mkdir -p $HOME/.config/zsh/extras
    '';
    
    initExtra = ''
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
      export XDG_CONFIG_HOME=$HOME/.config
      export ZSH_DISABLE_COMPFIX="true"

      # Source pre-path if exists
      [ -f "$HOME/.config/zsh/conf.d/path.pre.zsh" ] && source $HOME/.config/zsh/conf.d/path.pre.zsh

      # Set editor
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
        compinit -Ci
      done
      compinit -Ci
      
      # Load completions first
      _evalcache kubectl completion zsh
      _evalcache docker completion zsh
      _evalcache stern --completion zsh
      _evalcache gh completion -s zsh
      
      # Source configurations after completions are loaded
      for conf in $HOME/.config/zsh/conf.d/*.zsh; do
          [ -f "$conf" ] && source $conf
      done
      
      # Source other plugins
      source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      
      # Load all utility modules from extras directory
      for module in $HOME/.config/zsh/extras/*.sh; do
        if [[ -f "$module" ]]; then
          source "$module"
        fi
      done
      
      # Rest of tool initializations
      _evalcache direnv hook zsh
      _evalcache gh copilot alias -- zsh
      _evalcache starship init zsh
      _evalcache atuin init zsh
      
      # Fzf
      export FZF_DEFAULT_OPTS="
        --height 8
        --layout=reverse
        --border
        --inline-info
      "
      
      # Path settings
      # Rust
      [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
      export PATH="$HOME/.cargo/bin:$PATH"
      
      # Node.js
      export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
      
      # Python
      export PATH="/usr/local/opt/cython/bin:$PATH"
      export PATH="$PATH:$HOME/.local/bin"
      
      # Ruby
      export PATH="$HOME/.rvm/bin:$PATH"
      
      # Go
      export PATH="$HOME/.govm/shim:$PATH"
      export PATH="$PATH:$(go env GOPATH)/bin"
      
      # Kubernetes
      export PATH="$HOME/.krew/bin:$PATH"
      export PATH="$HOME/bin:$PATH"
      
      # GitHub username functions
      function ghwhoami() {
        gh api user --jq '.login' 2>/dev/null || echo 'Not logged in'
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
      compdef kubecolor=kubectl
      compdef k=kubectl
      
      # Source extras if they exist
      [ -f ~/.zshenv ] && source ~/.zshenv
      [ -f ~/.zshextras ] && source ~/.zshextras
      [ -f ~/.zshutils ] && source ~/.zshutils
      
      # Key bindings
      bindkey "^[[1;7C" forward-word
      bindkey "^[[1;7D" backward-word
      bindkey "^[[1;7B" beginning-of-line
      bindkey "^[[1;7A" end-of-line
    '';
  };
  
  # Copy utility scripts to the right location
  xdg.configFile = {
    # Kubernetes fuzzy finder
    "zsh/extras/kfzf.sh".source = ./kfzf.sh;
    
    # Kubernetes port forwarder
    "zsh/extras/kfwd.sh".source = ./kfwd.sh;
    
    # Kubernetes log viewer
    "zsh/extras/kellog.sh".source = ./kellog.sh;
    
    # GitHub repo finder
    "zsh/extras/crepo.sh".source = ./crepo.sh;
    
    # ZSH utilities
    "zsh/extras/zshutils.zsh".source = ./zshutils.zsh;
  };
}