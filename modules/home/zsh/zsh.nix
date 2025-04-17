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

  completionsScript = stripHeaders ./core/completions.sh;
  fzfScript = stripHeaders ./core/fzf.sh;
  logLibScript = stripHeaders ./core/loglib.sh;
  notificationsScript = stripHeaders ./core/notifications.sh;
  pathsScript = stripHeaders ./core/paths.sh;
  shiftSelectScript = stripHeaders ./core/shift-select.sh;
  styleScript = stripHeaders ./core/style.sh;
  kubectlAliasesScript = stripHeaders ./core/kubectl-aliases.sh;
  promptScript = stripHeaders ./core/prompt.sh;

  combinedCoreScripts = ''
    ${logLibScript}
    
    ${pathsScript}
    
    ${completionsScript}
    
    ${styleScript}
    
    ${fzfScript}
    
    ${notificationsScript}
    
    ${shiftSelectScript}

    ${kubectlAliasesScript}
    
    ${promptScript}
  ''; 
in
{
  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = true;
    historySubstringSearch.enable = true;
    autosuggestion = {
      enable = true;
      strategy = ["history" "completion"];
      highlight = "fg=#B4A7D6,bold";
    };

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
      ZSH_AUTOSUGGEST_USE_ASYNC = 1;
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = "20";
      ZSH_AUTOSUGGEST_MANUAL_REBIND = 1;
    };

    plugins = [
      {
        name = "fast-syntax-highlighting";
        src = pkgs.fetchFromGitHub {
          owner = "zdharma-continuum";
          repo = "fast-syntax-highlighting";
          rev = "cf318e0";
          sha256 = "sha256-RVX9ZSzjBW3LpFs2W86lKI6vtcvDWP6EPxzeTcRZua4=";
        };
        file = "fast-syntax-highlighting.plugin.zsh";
      }
      {
        name = "enhancd";
        file = "init.sh";
        src = pkgs.fetchFromGitHub {
          owner = "b4b4r07";
          repo = "enhancd";
          rev = "v2.2.1";
          sha256 = "0iqa9j09fwm6nj5rpip87x3hnvbbz9w9ajgm6wkrd5fls8fn8i5g";
        };
      }
    ];

    initExtraFirst = ''
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

      [[ -f "$HOME/.sysinit-debug" ]] && export SYSINIT_DEBUG=1
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
      autoload -Uz compinit
      if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
        compinit
      else
        compinit -C
      fi
      
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "$HOME/.zcompcache"
    '';
    
    dirHashes = {
      docs = "$HOME/Documents";
      dl = "$HOME/Downloads";
      dev = "$HOME/github";
    };
  };
  
  xdg.configFile = {
    "zsh/extras" = {
      source = ./extras;
      recursive = true;
      executable = true;
    };
  };
}