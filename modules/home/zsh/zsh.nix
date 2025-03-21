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
      # Basic utility functions
      function mkcd() { mkdir -p "$1" && cd "$1"; }
      
      # Load all utility modules from extras directory
      for module in $HOME/.config/zsh/extras/*.sh; do
        if [[ -f "$module" ]]; then
          source "$module"
        fi
      done
      
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
      
      # GitHub username functions
      function ghwhoami() {
        gh api user --jq '.login' 2>/dev/null || echo 'Not logged in'
      }
      
      function update_github_user() {
        export GITHUB_USER=$(ghwhoami)
      }
      
      # Update GitHub user on shell startup
      update_github_user
      
      # FZF integration
      export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --inline-info"
      
      # Disable ctrl+s to freeze terminal
      stty stop undef
      
      # For atuin integration
      eval "$(atuin init zsh --disable-up-arrow)"
      
      # Force rebuild of completion files
      autoload -Uz compinit
      compinit -u
      
      # Kubernetes completion
      compdef kubecolor=kubectl
      compdef k=kubectl
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