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
  prompt = stripHeaders ./core/prompt.sh;

  combinedCoreScripts = ''
    ${logLib}

    ${paths}

    ${wezterm}

    ${bindings}
                            
    ${kubectl}

    ${crepo}
    
    ${prompt}
  '';
in
{
  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = true;
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
    };

    sessionVariables = {
      ZSH_EVALCACHE_DIR = "$XDG_DATA_HOME/zsh/evalcache";

      ZSH_AUTOSUGGEST_USE_ASYNC = 1;
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = 20;
      ZSH_AUTOSUGGEST_MANUAL_REBIND = 1;
      ZSH_AUTOSUGGEST_STRATEGY = [
        "completion"
        "history"
      ];
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=#808080,bold,underline";

      EDITOR="nvim";
      SUDO_EDITOR="$EDITOR";
      VISUAL="$EDITOR";
      PAGER="bat --pager=always --color=always";
    };

    plugins = [
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
        name = "fast-syntax-highlighting";
        src = pkgs.fetchFromGitHub {
          owner = "zdharma-continuum";
          repo = "fast-syntax-highlighting";
          rev = "cf318e06a9b7c9f2219d78f41b46fa6e06011fd9";
          sha256 = "sha256-RVX9ZSzjBW3LpFs2W86lKI6vtcvDWP6EPxzeTcRZua4=";
        };
        file = "fast-syntax-highlighting.plugin.zsh";
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
        name = "evalcache";
        src = pkgs.fetchFromGitHub {
          owner = "mroth";
          repo = "evalcache";
          rev = "4c7fb8d5b319ae177fead3ec666e316ff2e13b90";
          sha256 = "sha256-qzpnGTrLnq5mNaLlsjSA6VESA88XBdN3Ku/YIgLCb28=";
        };
      }
    ];

    initExtraFirst = ''
      #!/usr/bin/env zsh
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
      
      typeset -U path cdpath fpath manpath
      
      unset MAILCHECK
      stty stop undef
    '';
    
    initExtra = ''
      ${combinedCoreScripts}
    
      if [[ -d "$HOME/.config/zsh/extras" ]]; then
        for file in "$HOME/.config/zsh/extras/"*.sh(N); do
          if [[ -f "$file" ]]; then
            if [[ -n "$SYSINIT_DEBUG" ]]; then
              log_debug "Sourcing file" path="$file"
              source "$file"
            else
              source "$file"
            fi
          fi
        done
      fi
      
      [[ -n "$SYSINIT_DEBUG" ]] && zprof
    '';
    
    completionInit = ''
      # fzf-tab configuration
      zstyle ':fzf-tab:*' fzf-command fzf
      zstyle ':fzf-tab:*' fzf-min-height 50
      zstyle ':fzf-tab:*' fzf-pad 4
      
      # Use the same colors as fzf default
      zstyle ':fzf-tab:*' fzf-flags --color=border:-1,fg:-1,bg:-1,hl:6,fg+:12,bg+:-1,hl+:12,info:7
      
      # Show file previews for file/dir completions
      zstyle ':fzf-tab:complete:ls:*' fzf-preview 'eza -1 --color=always --icons --git-ignore --git $realpath'
      zstyle ':fzf-tab:complete:cp:*' fzf-preview 'eza -1 --color=always --icons --git-ignore --git $realpath'
      zstyle ':fzf-tab:complete:mv:*' fzf-preview 'eza -1 --color=always --icons --git-ignore --git $realpath'
      zstyle ':fzf-tab:complete:rm:*' fzf-preview 'eza -1 --color=always --icons --git-ignore --git $realpath'
      
      # Use enhancd fzf instead
      zstyle ':fzf-tab:complete:cd:*' disabled-on any

      # Preview content for text files
      zstyle ':fzf-tab:complete:cat:*' fzf-preview 'bat --color=always --style=numbers,header {}'
      zstyle ':fzf-tab:complete:vim:*' fzf-preview 'bat --color=always --style=numbers,header {}'
      zstyle ':fzf-tab:complete:nvim:*' fzf-preview 'bat --color=always --style=numbers,header {}'
      
      # Show systemd unit status
      zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
      
      # Environment variables
      zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
        fzf-preview 'echo ''\${(P)word}'
      
      # Git preview support
      zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview \
        'git diff $word | delta'
      zstyle ':fzf-tab:complete:git-log:*' fzf-preview \
        'git log --color=always $word'
      zstyle ':fzf-tab:complete:git-help:*' fzf-preview \
        'git help $word | bat --color=always --language=man'
      zstyle ':fzf-tab:complete:git-show:*' fzf-preview \
        'case "$group" in
          "commit tag") git show --color=always $word ;;
          *) git show --color=always $word | delta ;;
        esac'
      zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview \
        'case "$group" in
          "modified file") git diff $word | delta ;;
          "remote branch") git log --color=always $word ;;
          *) git log --color=always $word ;;
        esac'
        
      # General settings
      zstyle ':fzf-tab:*' default-color $'\033[37m'
      zstyle ':fzf-tab:*' show-group full
      zstyle ':fzf-tab:*' prefix ''\''
      zstyle ':fzf-tab:*' single-group color header
      zstyle ':fzf-tab:*' switch-group 'alt-p' 'alt-n'
      
      # Completion configuration
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "$HOME/.zcompcache"
      zstyle ':completion:*' list-colors ''\${(s.:.)LS_COLORS}
      zstyle ':completion:*' menu no
      zstyle ':completion:*' fzf-preview 'echo ''\${(P)word}'

      autoload -Uz compinit
      if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
        compinit
      else
        compinit -C
      fi
    '';
    
    dirHashes = {
      docs = "$HOME/Documents";
      dl = "$HOME/Downloads";
      ghp = "$HOME/github/personal";
      ghpr = "$HOME/github/personal/roshbhatia";
      ghw = "$HOME/github/work";
    };
  };
  
  xdg.configFile = {
    "zsh/bin" = {
      source = ./bin;
      recursive = true;
      executable = true;
    };
  };

  home.activation.prepareZshDirs = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    echo "Preparing zsh directories..."
    rm -rf "$HOME/.config/zsh/extras" # Clean old symlinks
    mkdir -p -m 755 "$HOME/.config/zsh/"{bin,extras,extras/bin}
    chmod -R 755 "$HOME/.config/zsh"
  '';
}