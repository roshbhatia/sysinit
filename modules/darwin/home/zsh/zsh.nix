{ config, lib, pkgs, ... }:

let
  stripHeaders = file: let
    content = builtins.readFile file;
    lines = lib.splitString "\n" content;
    isHeaderLine = line:
      lib.hasPrefix "#!/usr/bin/env zsh" line ||
      lib.hasPrefix "# THIS FILE WAS INSTALLED BY SYSINIT" line ||
      lib.hasPrefix "# shellcheck disable" line;
    nonHeaderLines = builtins.filter (line: !(isHeaderLine line)) lines;
  in lib.concatStringsSep "\n" nonHeaderLines;

  logLib = stripHeaders ./core/loglib.sh;
  paths = stripHeaders ./core/paths.sh;
  wezterm = stripHeaders ./core/wezterm.sh;
  bindings = stripHeaders ./core/bindings.sh;
  completions = stripHeaders ./core/completions.sh;
  kubectl = stripHeaders ./core/kubectl.sh;
  crepo = stripHeaders ./core/crepo.sh;
  extras = stripHeaders ./core/extras.sh;
  prompt = stripHeaders ./core/prompt.sh;

  combinedCoreScripts = ''
    ${logLib}

    ${paths}

    ${wezterm}

    ${bindings}

    ${kubectl}

    ${crepo}

    ${completions}

    ${extras}

    ${prompt}
  '';
in
{
  programs.zsh = {
    enable = true;

    autocd = true;
    # We enable completion anyways, we don't want our cache to be invalidated.
    enableCompletion = false;
    historySubstringSearch.enable = false;
    # We need to install this manually due to fzf-tab needing to run first
    autosuggestion.enable = false;
    # We use fast-syntax-highlighting instead
    syntaxHighlighting.enable = false;

    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
      share = true;
    };

    dirHashes = {
      dsk = "$HOME/Desktop";
      docs = "$HOME/Documents";
      dl = "$HOME/Downloads";
      ghp = "$HOME/github/personal";
      ghpr = "$HOME/github/personal/roshbhatia";
      ghw = "$HOME/github/work";
    };
    
    shellAliases = {
      "....." = "cd ../../../..";
      "...." = "cd ../../..";
      "..." = "cd ../..";
      ".." = "cd ..";
      "~" = "cd ~";
      
      code = "code-insiders";
      kubectl = "kubecolor";
      
      l = "eza --icons=always -1";
      la = "eza --icons=always -1 -a";
      ll = "eza --icons=always -1 -a";
      ls = "eza";
      lt = "eza --icons=always -1 -a -T";
      
      tf = "terraform";
      y = "yazi";
      
      vim = "nvim";
      vi = "nvim";
      
      sudo = "sudo -E";

      diff = "diff --color";
      grep = "grep -s --color=auto";
    };
    
    sessionVariables = {
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";

      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";

      ZSH_EVALCACHE_DIR = "$XDG_DATA_HOME/zsh/evalcache";

      ZSH_AUTOSUGGEST_USE_ASYNC = 1;
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = 20;
      ZSH_AUTOSUGGEST_MANUAL_REBIND = 1;
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=#808080,bold,underline";

      FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules";
      FZF_DEFAULT_OPTS = builtins.concatStringsSep " " [
        "--preview-window=right:60%:wrap:border-rounded"
        "--height=80%"
        "--layout=reverse"
        "--border=rounded"
        "--margin=1"
        "--padding=1"
        "--info=inline-right"
        "--prompt='❯ '"
        "--pointer='▶'"
        "--marker='✓'"
        "--scrollbar='█'"
        "--color=border:-1,fg:-1,bg:-1,hl:6,fg+:12,bg+:-1,hl+:12,info:7"
        "--color=prompt:1,pointer:5,marker:2,spinner:5,header:4"
        "--preview='sysinit-fzf-preview {}'"
        "--bind='ctrl-/:toggle-preview'"        # Toggle preview window
        "--bind='ctrl-s:toggle-sort'"           # Toggle sorting
        "--bind='ctrl-space:toggle-preview-wrap'" # Toggle preview wrap
        "--bind='tab:half-page-down'"           # Scroll preview down
        "--bind='btab:half-page-up'"            # Scroll preview up
        "--bind='ctrl-u:clear-query'"           # Clear query
        "--bind='resize:refresh-preview'"       # Refresh on resize
      ];

      # Enhanced cd navigation
      ENHANCD_FILTER = "fzf --height=35% --reverse --border=rounded --inline-info --preview='sysinit-fzf-preview {}'";
      ENHANCD_ENABLE_DOUBLE_DOT = false;
      ENHANCD_ENABLE_HOME = false;

      EDITOR = "nvim";
      SUDO_EDITOR = "$EDITOR";
      VISUAL = "$EDITOR";
      PAGER = "bat --pager=always --color=always";
    };

    plugins = [
      {
        name = "evalcache";
        src = pkgs.fetchFromGitHub {
          owner = "mroth";
          repo = "evalcache";
          rev = "3153dcd77a2c93aa8fdf5d17cece7edb1aa3e040";
          sha256 = "GAjsTQJs9JdBEf9LGurme3zqXN//kVUM2YeBo0sCR2c=";
        };
        file = "evalcache.plugin.zsh";
      }
      {
        name = "enhancd";
        src = pkgs.fetchFromGitHub {
          owner = "babarot";
          repo = "enhancd";
          rev = "5afb4eb6ba36c15821de6e39c0a7bb9d6b0ba415";
          sha256 = "sha256-pKQbwiqE0KdmRDbHQcW18WfxyJSsKfymWt/TboY2iic=";
        };
        file = "enhancd.plugin.zsh";
      }
      {
        name = "fzf-tab";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "v1.2.0";
          sha256 = "sha256-q26XVS/LcyZPRqDNwKKA9exgBByE0muyuNb0Bbar2lY=";
        };
        file = "fzf-tab.plugin.zsh";
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "0e810e5afa27acbd074398eefbe28d13005dbc15";
          sha256 = "sha256-85aw9OM2pQPsWklXjuNOzp9El1MsNb+cIiZQVHUzBnk=";
        };
        file = "zsh-autosuggestions.plugin.zsh";
      }
      {
        name = "fast-syntax-highlighting";
        src = pkgs.fetchFromGitHub {
          owner = "zdharma-continuum";
          repo = "fast-syntax-highlighting";
          rev = "cf318e06a9b7c9f2219d78f41b46fa6e06011fd9";
          sha256 = "sha256-RVX9ZSzjBW3LpFs2W86lKI6vtcvDWP6EPxzeTcRZua4=";
        };
        file = "fast-syntax-highlighting.plugin.zsh";
      }
    ];

    initExtraFirst = ''
      # modules/darwin/home/zsh/zsh.nix#initExtraFirst (begin)
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

      [[ -n "$SYSINIT_DEBUG" ]] && zmodload zsh/zprof
            
      unset MAILCHECK
      stty stop undef

      # Instant prompt: minimal prompt to avoid blank screen
      setopt PROMPT_SUBST
      PROMPT='%~%# '
      RPS1=""
      # modules/darwin/home/zsh/zsh.nix#initExtraFirst (end)
    '';
    
    completionInit = ''
      # Create zcompdump directory and load completions
      mkdir -p "''\${XDG_DATA_HOME}/zsh/zcompdump"
      autoload -Uz compinit
      if [[ -n ''\${XDG_DATA_HOME}/zsh/zcompdump/.zcompdump(#qN.mh+24) ]]; then
        compinit -d "''\${XDG_DATA_HOME}/zsh/zcompdump/.zcompdump";
      else
        compinit -C -d "''\${XDG_DATA_HOME}/zsh/zcompdump/.zcompdump";
      fi

      # Basic completion configuration
      zstyle ':completion:*' menu no
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*:descriptions' format '[%d]'

      # FZF-tab configuration
      zstyle ':fzf-tab:*' fzf-command fzf
      zstyle ':fzf-tab:*' fzf-min-height 50
      zstyle ':fzf-tab:*' fzf-pad 4
      zstyle ':fzf-tab:*' continuous-trigger '/'
      zstyle ':fzf-tab:*' switch-group 'alt-p' 'alt-n'
      zstyle ':fzf-tab:*' default-color $'\033[37m'
      zstyle ':fzf-tab:*' show-group full
      zstyle ':fzf-tab:*' prefix ''\''
      zstyle ':fzf-tab:*' single-group color header

      # Preview configurations
      zstyle ':fzf-tab:*' fzf-flags --preview-window=right:60%:wrap:border-rounded --height=80% --layout=reverse --border=rounded --margin=1 --padding=1 --info=inline-right --prompt='❯ ' --pointer='▶' --marker='✓' --scrollbar='█' --color=border:-1,fg:-1,bg:-1,hl:6,fg+:12,bg+:-1,hl+:12,info:7 --color=prompt:1,pointer:5,marker:2,spinner:5,header:4 --bind='ctrl-/:toggle-preview' --bind='ctrl-s:toggle-sort' --bind='ctrl-space:toggle-preview-wrap' --bind='tab:half-page-down' --bind='btab:half-page-up' --bind='ctrl-y:preview-up' --bind='ctrl-e:preview-down' --bind='?:toggle-preview' --bind='alt-w:toggle-preview-wrap' --bind='ctrl-u:clear-query' --bind='resize:refresh-preview' --preview='sysinit-fzf-preview {}'
      zstyle ':fzf-tab:*' fzf-preview 'sysinit-fzf-preview {}'
      zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word 2>/dev/null || echo "No unit status available"'
      zstyle ':fzf-tab:complete:git-*:*' fzf-preview 'sysinit-fzf-preview {}'
      zstyle ':fzf-tab:complete:kubectl-*:*' fzf-preview 'if [[ {} == *.@(yml|yaml) ]]; then bat --color=always --style=numbers,header,grid --language=yaml --line-range :100 {}; else sysinit-fzf-preview {}; fi'
      
      # Disable fzf-tab for cd (using enhancd instead)
      zstyle ':fzf-tab:complete:cd:*' disabled-on any

      # Load and configure fzf-tab
      autoload -Uz +X _fzf_tab_complete 2>/dev/null
      _setup_fzf_tab_bindings() { (( $+widgets[fzf-tab-complete] )) && bindkey '^I' fzf-tab-complete }
      autoload -Uz add-zsh-hook
      add-zsh-hook precmd _setup_fzf_tab_bindings

      # Unbind alt-p, alt-n, alt-w to free these keys for fzf-tab
      bindkey -r '\ep'
      bindkey -r '\en'
      bindkey -r '\ew'
    '';
  
    initExtra = ''
      # modules/darwin/home/zsh/zsh.nix#initExtra (begin)
      ${combinedCoreScripts}
      
      enable-fzf-tab
          
      [[ -n "$SYSINIT_DEBUG" ]] && zprof
      # modules/darwin/home/zsh/zsh.nix#initExtra (end)
    '';
  };
  
  xdg.configFile = {
    "zsh/bin" = {
      source = ./bin;
      recursive = true;
      executable = true;
    };
  };

  home.activation.prepareZshDirs = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    echo "Preparing zsh extras directory..."
    
    mkdir -p -m 755 "$HOME/.config/zsh"
    
    rm -rf "$HOME/.config/zsh/extras"
    rm -rf "$HOME/.config/zsh/bin"

    mkdir -p -m 755 "$HOME/.config/zsh/extras" "$HOME/.config/zsh/bin"
  '';
}