{ config, lib, pkgs, ... }:

let
  stripHeaders = file: let
    content = builtins.readFile file;
    lines = lib.splitString "\n" content;
    nonCommentLines = builtins.filter (line:
      let 
        # Manual trim of left whitespace using string operations
        trimmedLine = builtins.match "[ \t]*(.*)" line;
        trimmed = if trimmedLine == null then line else builtins.elemAt trimmedLine 0;
      in
        !(lib.hasPrefix "#" trimmed)
    ) lines;
  in lib.concatStringsSep "\n" nonCommentLines;

  pre = stripHeaders ./core/00-pre.sh;
  logLib = stripHeaders ./core/01-loglib.sh;
  paths = stripHeaders ./core/02-paths.sh;
  shellIntegration = stripHeaders ./core/03-shell-integration.sh;
  bindings = stripHeaders ./core/04-bindings.sh;
  aliases = stripHeaders ./core/05-aliases.sh;
  crepo = stripHeaders ./core/06-crepo.sh;
  prompt = stripHeaders ./core/07-prompt.sh;
  post = stripHeaders ./core/08-post.sh;

  completions = stripHeaders ./core/00-completions.sh;
in
{
  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = false; # We're managing completions manually
    historySubstringSearch.enable = true;
    # We need to install this manually due to fzf-tab needing to run first
    autosuggestion.enable = false;

    syntaxHighlighting.enable = false;

    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
      share = true;
    };

    sessionVariables = {
      ZSH_EVALCACHE_DIR = "$XDG_DATA_HOME/zsh/evalcache";

      EDITOR="nvim";
      SUDO_EDITOR="$EDITOR";
      VISUAL="$EDITOR";
      PAGER="bat --pager=always --color=always";
    };

    plugins = [];

    initExtraFirst = ''
      # !/usr/bin/env zsh
      # THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
      # shellcheck disable=all
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
      
      ${pre}
    '';
    
    initExtra = ''
      # Load plugins directly with full paths to avoid fpath issues
      # The logs show the plugin is at ~/.zsh/plugins/fzf-tab/
      if [[ -f "$HOME/.zsh/plugins/fzf-tab/fzf-tab.plugin.zsh" ]]; then
        echo "Loading fzf-tab from $HOME/.zsh/plugins/fzf-tab/fzf-tab.plugin.zsh"
        source "$HOME/.zsh/plugins/fzf-tab/fzf-tab.plugin.zsh"
      elif [[ -f "$HOME/.nix-profile/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh" ]]; then
        echo "Loading fzf-tab from nix profile"
        source "$HOME/.nix-profile/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh"
      else
        echo "WARNING: Could not find fzf-tab plugin"
      fi
      
      # Try to load other plugins directly
      [[ -f "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh" ]] && \
        source "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"
      
      [[ -f "$HOME/.zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]] && \
        source "$HOME/.zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
      
      # Load evalcache
      [[ -f "$HOME/.zsh/plugins/evalcache/evalcache.plugin.zsh" ]] && \
        source "$HOME/.zsh/plugins/evalcache/evalcache.plugin.zsh"
      
      # Load enhancd
      [[ -f "$HOME/.zsh/plugins/enhancd/init.sh" ]] && \
        source "$HOME/.zsh/plugins/enhancd/init.sh"
      
      # Verify fzf-tab loaded correctly
      if typeset -f _fzf_tab_complete >/dev/null 2>&1; then
        echo "fzf-tab loaded successfully"
      else
        echo "WARNING: fzf-tab did not load correctly"
      fi
      
      ${completions}

      ${logLib}

      ${paths}

      ${shellIntegration}

      ${bindings}

      ${aliases}

      ${crepo}

      ${prompt}

      ${post}
    '';
  };
  
  xdg.configFile = {
    "zsh/bin" = {
      source = ./bin;
      recursive = true;
      executable = true;
    };
    "zsh/reset-zsh.sh" = {
      source = ./reset-zsh.sh;
      executable = true;
    };
  };

  home.activation.prepareZshDirs = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    echo "Preparing zsh extras directory..."
    # Ensure base config dir exists
    mkdir -p -m 755 "$HOME/.config/zsh"
    # Clean old extras symlinks
    rm -rf "$HOME/.config/zsh/extras"
    # Create extras and extras/bin
    mkdir -p -m 755 "$HOME/.config/zsh/extras" "$HOME/.config/zsh/extras/bin"
    # Create a placeholder file to avoid "no matches found" error
    touch "$HOME/.config/zsh/extras/placeholder.sh"
    
    # Setup ZSH plugins directly in the activation script
    echo "Setting up ZSH plugins..."
    PLUGIN_DIR="$HOME/.zsh/plugins"
    mkdir -p "$PLUGIN_DIR"
    
    # Install fzf-tab
    if [[ ! -d "$PLUGIN_DIR/fzf-tab" ]]; then
      echo "Installing fzf-tab..."
      git clone --depth 1 https://github.com/Aloxaf/fzf-tab.git "$PLUGIN_DIR/fzf-tab"
    else
      echo "fzf-tab already installed"
    fi
    
    # Install zsh-autosuggestions
    if [[ ! -d "$PLUGIN_DIR/zsh-autosuggestions" ]]; then
      echo "Installing zsh-autosuggestions..."
      git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git "$PLUGIN_DIR/zsh-autosuggestions"
    else
      echo "zsh-autosuggestions already installed"
    fi
    
    # Install fast-syntax-highlighting
    if [[ ! -d "$PLUGIN_DIR/fast-syntax-highlighting" ]]; then
      echo "Installing fast-syntax-highlighting..."
      git clone --depth 1 https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$PLUGIN_DIR/fast-syntax-highlighting"
    else
      echo "fast-syntax-highlighting already installed"
    fi
    
    # Install evalcache
    if [[ ! -d "$PLUGIN_DIR/evalcache" ]]; then
      echo "Installing evalcache..."
      git clone --depth 1 https://github.com/mroth/evalcache.git "$PLUGIN_DIR/evalcache"
    else
      echo "evalcache already installed"
    fi
    
    # Install enhancd
    if [[ ! -d "$PLUGIN_DIR/enhancd" ]]; then
      echo "Installing enhancd..."
      git clone --depth 1 https://github.com/babarot/enhancd.git "$PLUGIN_DIR/enhancd"
    else
      echo "enhancd already installed"
    fi
    
    echo "Done installing ZSH plugins"
  '';
}