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

    ${completions}

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
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";

      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";

      ZSH_SMARTCACHE_DIR = "$XDG_DATA_HOME/zsh/smartcache";

      ZSH_AUTOSUGGEST_USE_ASYNC = 1;
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = 20;
      ZSH_AUTOSUGGEST_MANUAL_REBIND = 1;
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=#808080,bold,underline";

      EDITOR="nvim";
      SUDO_EDITOR="$EDITOR";
      VISUAL="$EDITOR";
      PAGER="bat --pager=always --color=always";
    };

    plugins = [
      {
        name = "zsh-smartcache";
        src = pkgs.fetchFromGitHub {
          owner = "QuarticCat";
          repo = "zsh-smartcache";
          rev = "641dbfa196c9f69264ad7a49f9ef180af75831be";
          sha256 = "sha256-t6QbAMFJfCvEOtq1y/YXZz5eyyc5OHOM/xg3cgXNcjU=";
        };
        file = "zsh-smartcache.plugin.zsh";
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
      setopt EXTENDED_GLOB
      
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

      if [[ -f "$HOME/.zshwork" ]]; then
        source $HOME/.zshwork
      fi
      if [[ -f "$HOME/.zshsecrets" ]]; then
        source $HOME/.zshsecrets
      fi
      
      [[ -n "$SYSINIT_DEBUG" ]] && zprof
    '';

    completionInit = ''
      # Basic fzf-tab configuration
      # Set descriptions format to enable group support
      zstyle ':completion:*:descriptions' format '[%d]'
      
      # Set list-colors to enable filename colorizing
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      
      # Force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
      zstyle ':completion:*' menu no
      
      # Import your FZF settings
      ${completions}
      
      # Define preview command for different file types
      preview_command="
      if [[ -d \$realpath ]]; then
        eza -la --color=always --icons --git-ignore --git --group-directories-first \$realpath
      elif [[ -f \$realpath ]]; then
        case \$realpath in
          *.md)
            glow -s dark \$realpath
            ;;
          *.json)
            jq -C . \$realpath
            ;;
          *.js|*.jsx|*.ts|*.tsx|*.html|*.css|*.yml|*.yaml|*.toml|*.nix|*.sh|*.zsh|*.bash|*.fish)
            bat --color=always --style=numbers,header,grid --line-range :100 \$realpath
            ;;
          *.jpg|*.jpeg|*.png|*.gif)
            kitten icat \$realpath 2>/dev/null || imgcat \$realpath 2>/dev/null || echo \"Image preview not available\"
            ;;
          *)
            bat --color=always --style=numbers,header,grid --line-range :100 \$realpath || cat \$realpath
            ;;
        esac
      else
        echo \$realpath
      fi
      "
      
      # Use the same FZF appearance settings from your configuration
      zstyle ':fzf-tab:*' fzf-flags --preview-window=right:60%,wrap,border-rounded --height=80% --layout=reverse --border=rounded --margin=1 --padding=1 --info=inline-right --prompt='❯ ' --pointer='▶' --marker='✓' --scrollbar='█' --color=border:-1,fg:-1,bg:-1,hl:6,fg+:12,bg+:-1,hl+:12,info:7 --color=prompt:1,pointer:5,marker:2,spinner:5,header:4 --bind='ctrl-/:toggle-preview' --bind='ctrl-s:toggle-sort' --bind='ctrl-space:toggle-preview-wrap' --bind='tab:half-page-down' --bind='btab:half-page-up' --bind='ctrl-y:preview-up' --bind='ctrl-e:preview-down' --bind='?:toggle-preview' --bind='alt-w:toggle-preview-wrap' --bind='ctrl-u:clear-query' --bind='resize:refresh-preview'
      
      # Apply preview command to different completion contexts
      zstyle ':fzf-tab:complete:cd:*' fzf-preview $preview_command
      zstyle ':fzf-tab:complete:ls:*' fzf-preview $preview_command
      zstyle ':fzf-tab:complete:nvim:*' fzf-preview $preview_command
      zstyle ':fzf-tab:complete:vim:*' fzf-preview $preview_command
      zstyle ':fzf-tab:complete:cat:*' fzf-preview $preview_command
      zstyle ':fzf-tab:complete:cp:*' fzf-preview $preview_command
      zstyle ':fzf-tab:complete:mv:*' fzf-preview $preview_command
      zstyle ':fzf-tab:complete:rm:*' fzf-preview $preview_command
      
      # Apply preview command as default for all other completions
      zstyle ':fzf-tab:*' fzf-preview $preview_command
      
      # Show systemd unit status
      zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word 2>/dev/null || echo "No unit status available"'
      
      # Git preview with delta
      git_preview="
      if [[ -d \$realpath ]]; then
        eza -la --color=always --icons --git-ignore --git --group-directories-first \$realpath
      elif [[ -f \$realpath ]]; then
        git diff --color=always \$realpath 2>/dev/null | delta || bat --color=always --style=numbers,header,grid --line-range :100 \$realpath
      else
        git status -s \$word 2>/dev/null || echo \$word
      fi
      "
      
      zstyle ':fzf-tab:complete:git-*:*' fzf-preview $git_preview
      
      # Add kubectl file previewing
      kubectl_preview="
      if [[ -f \$realpath && (\$realpath == *.yml || \$realpath == *.yaml) ]]; then
        bat --color=always --style=numbers,header,grid --language=yaml --line-range :100 \$realpath
      else
        $preview_command
      fi
      "
      
      zstyle ':fzf-tab:complete:kubectl-*:*' fzf-preview $kubectl_preview
      
      # Switch groups using alt-p and alt-n
      zstyle ':fzf-tab:*' switch-group 'alt-p' 'alt-n'
      
      # fzf appearance and behavior 
      zstyle ':fzf-tab:*' fzf-command fzf
      zstyle ':fzf-tab:*' fzf-min-height 50
      zstyle ':fzf-tab:*' fzf-pad 4
      
      # Enable continuous preview when Ctrl+/ is pressed
      zstyle ':fzf-tab:*' continuous-trigger '/'
      
      # General settings
      zstyle ':fzf-tab:*' default-color $'\033[37m'
      zstyle ':fzf-tab:*' show-group full
      zstyle ':fzf-tab:*' prefix ''\''
      zstyle ':fzf-tab:*' single-group color header
      
      # Use enhancd fzf instead for cd
      zstyle ':fzf-tab:complete:cd:*' disabled-on any
      
      # Autocompletion settings
      autoload -Uz compinit
      if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
        compinit
      else
        compinit -C
      fi
      
      # Fix autosuggestion strategy syntax
      export ZSH_AUTOSUGGEST_STRATEGY=(completion history)
      
      # Add explicit key binding for accepting suggestions with Shift-Tab
      bindkey '^[[Z' autosuggest-accept  # Shift-Tab
      
      # Make sure fzf-tab is loaded properly
      autoload -Uz +X _fzf_tab_complete 2>/dev/null
      
      # This is crucial: ensure the key binding is set after plugins are loaded
      _setup_fzf_tab_bindings() {
        # Only rebind if fzf-tab-complete exists
        (( $+widgets[fzf-tab-complete] )) && bindkey '^I' fzf-tab-complete
      }
      
      # Add the setup function to precmd hook to ensure it runs after all plugins load
      autoload -Uz add-zsh-hook
      add-zsh-hook precmd _setup_fzf_tab_bindings

      # Enable fzf-tab plugin if available
      type enable-fzf-tab >/dev/null 2>&1 && enable-fzf-tab
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
    echo "Preparing zsh extras directory..."
    # Ensure base config dir exists
    mkdir -p -m 755 "$HOME/.config/zsh"
    # Clean old extras symlinks
    rm -rf "$HOME/.config/zsh/extras"
    # Create extras and extras/bin
    mkdir -p -m 755 "$HOME/.config/zsh/extras" "$HOME/.config/zsh/extras/bin"
  '';
}