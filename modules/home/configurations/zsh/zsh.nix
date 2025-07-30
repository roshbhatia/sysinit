{
  config,
  lib,
  pkgs,
  values,
  ...
}:
let
  shell = import ../../../lib/shell { inherit lib; };
  themes = import ../../../lib/themes { inherit lib; };
  paths_lib = import ../../../lib/paths { inherit config lib; };
  appTheme = themes.getAppTheme "vivid" values.theme.colorscheme values.theme.variant;
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  ansiCodes =
    themes.ansiMappings.${values.theme.colorscheme}.${values.theme.variant}
      or themes.ansiMappings.catppuccin.macchiato;
  pathsList = paths_lib.getAllPaths config.home.username config.home.homeDirectory;
  wezterm = shell.stripHeaders ./core/wezterm.sh;
  completions = shell.stripHeaders ./core/completions.sh;
  kubectl = shell.stripHeaders ./core/kubectl.sh;
  env = shell.stripHeaders ./core/env.sh;
  extras = shell.stripHeaders ./core/extras.sh;
  prompt = shell.stripHeaders ./core/prompt.sh;
in
{
  programs.carapace.enableZshIntegration = true;

  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = false;
    historySubstringSearch.enable = false;
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
    dirHashes = {
      dl = "${config.home.homeDirectory}/Downloads";
      docs = "${config.home.homeDirectory}/Documents";
      dsk = "${config.home.homeDirectory}/Desktop";
      ghp = "${config.home.homeDirectory}/github/personal";
      ghpr = "${config.home.homeDirectory}/github/personal/roshbhatia";
      ghw = "${config.home.homeDirectory}/github/work";
      nvim = "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim";
      sysinit = "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit";
    };
    shellAliases = {
      "....." = "cd ../../../..";
      "...." = "cd ../../..";
      "..." = "cd ../..";
      ".." = "cd ..";
      "~" = "cd ~";
      code = "code-insiders";
      c = "code-insiders";
      kubectl = "kubecolor";
      l = "eza --icons=always -1";
      la = "eza --icons=always -1 -a";
      ll = "eza --icons=always -1 -a";
      ls = "eza";
      lt = "eza --icons=always -1 -a -T --git-ignore --ignore-glob='.git'";
      tf = "terraform";
      y = "yazi";
      v = "nvim";
      g = "git";
      sudo = "sudo -E";
      diff = "diff --color";
      grep = "grep -s --color=auto";
      watch = "watch --color --no-title";
    };
    sessionVariables = {
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      SUDO_EDITOR = "nvim";
      VISUAL = "nvim";
      GIT_DISCOVERY_ACROSS_FILESYSTEM = 1;
      ZSH_EVALCACHE_DIR = "${config.xdg.dataHome}/zsh/evalcache";
      ZSH_AUTOSUGGEST_USE_ASYNC = 1;
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = 20;
      ZSH_AUTOSUGGEST_MANUAL_REBIND = 1;
      ZVM_LINE_INIT_MODE = "i";
      FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules";
      FZF_DEFAULT_OPTS = builtins.concatStringsSep " " [
        "--bind='resize:refresh-preview'"
        "--color=bg+:-1,bg:-1,spinner:${palette.accent or "#8aadf4"},hl:${palette.accent or "#8aadf4"}"
        "--color=border:${
          palette.surface2 or palette.overlay or "#5b6078"
        },label:${palette.text or "#cad3f5"}"
        "--color=fg:${palette.text or "#cad3f5"},header:${palette.accent or "#8aadf4"},info:${palette.subtext1 or "#b8c0e0"},pointer:${palette.accent or "#8aadf4"}"
        "--color=marker:${palette.accent or "#8aadf4"},fg+:${palette.text or "#cad3f5"},prompt:${palette.accent or "#8aadf4"},hl+:${palette.accent or "#8aadf4"}"
        "--cycle"
        "--height=30"
        "--highlight-line"
        "--ignore-case"
        "--info=inline"
        "--input-border=rounded"
        "--layout=reverse"
        "--list-border=rounded"
        "--no-scrollbar"
        "--pointer='>'"
        "--preview-border=rounded"
        "--prompt='>> '"
        "--scheme='history'"
        "--style='minimal'"
      ];
      COLIMA_HOME = "${config.xdg.configHome}/colima";
      VIVID_THEME = appTheme;
    };
    plugins = [
      {
        name = "zsh-vi-mode";
        src = pkgs.fetchFromGitHub {
          owner = "jeffreytse";
          repo = "zsh-vi-mode";
          rev = "v0.11.0";
          sha256 = "sha256-xbchXJTFWeABTwq6h4KWLh+EvydDrDzcY9AQVK65RS8=";
        };
        file = "zsh-vi-mode.plugin.zsh";
      }
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
    initContent = lib.mkMerge [
      (lib.mkBefore ''
        [[ -n "$SYSINIT_DEBUG" ]] && zmodload zsh/zprof
        unset MAILCHECK
        stty stop undef
        setopt COMBINING_CHARS
        setopt PROMPT_SUBST
        PROMPT='%~%# '
        RPS1=""
      '')
      (lib.mkOrder 550 ''
        mkdir -p ${config.xdg.configHome}/zsh
        autoload bashcompinit && bashcompinit
        autoload -Uz compinit
        if [[ -n ${config.xdg.configHome}/zsh/zcompdump/.zcompdump(#qN.mh+24) ]]; then
          compinit -d "${config.xdg.configHome}/zsh/zcompdump/.zcompdump";
        else
          compinit -C -d "${config.xdg.configHome}/zsh/zcompdump/.zcompdump";
        fi

        zstyle ':completion:*:git-checkout:*' sort false
        zstyle ':completion:*:descriptions' format '[%d]'
        zstyle ':completion:*' list-colors ''\${(s.:.)LS_COLORS}
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
        zstyle ':completion:*:complete:*' use-cache on
        zstyle ':completion:*' menu no

        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'fzf-preview "$realpath"'
        zstyle ':fzf-tab:complete:cat:*' fzf-preview  'fzf-preview "$realpath"'
        zstyle ':fzf-tab:complete:bat:*' fzf-preview  'fzf-preview "$realpath"'
        zstyle ':fzf-tab:complete:nvim:*' fzf-preview 'fzf-preview "$realpath"'
        zstyle ':fzf-tab:complete:vim:*' fzf-preview 'fzf-preview "$realpath"'
        zstyle ':fzf-tab:complete:vi:*' fzf-preview 'fzf-preview "$realpath"'
        zstyle ':fzf-tab:complete:v:*' fzf-preview 'fzf-preview "$realpath"'

        zstyle ':fzf-tab:*' use-fzf-default-opts yes
      '')
      ''
        path.print() {
          echo "$PATH" | tr ':' '\n' | bat --style=numbers,grid
        }

        path.add.safe() {
          local dir="$1"
          if [ -d "$dir" ]; then
            if [[ ":$PATH:" != *":$dir:"* ]]; then
              export PATH="$dir:$PATH"
              [[ -n "$SYSINIT_DEBUG" ]] && echo "Added $dir to PATH"
            fi
          else
            [[ -n "$SYSINIT_DEBUG" ]] && echo "Directory $dir does not exist, skipping PATH addition"
          fi
        }

        paths=(
          ${lib.concatStringsSep "\n          " (map (path: "\"${path}\"") pathsList)}
        )

        for dir in "''${paths[@]}"; do
          path.add.safe "$dir"
        done

        ${wezterm}
        ${kubectl}
        ${env}
        ${extras}
        ${completions}
        ${prompt}
        if command -v carapace &>/dev/null; then
          eval "$(carapace _carapace)"
        fi
      ''
      (lib.mkAfter ''
        # Vi mode integration with oh-my-posh
        _omp_redraw-prompt() {
          local precmd
          for precmd in "''${precmd_functions[@]}"; do
            "$precmd"
          done
          zle && zle reset-prompt
        }

        export POSH_VI_MODE="> "

        function zvm_after_select_vi_mode() {
          case $ZVM_MODE in
          $ZVM_MODE_NORMAL)
            POSH_VI_MODE="| "
            ;;
          $ZVM_MODE_INSERT)
            POSH_VI_MODE="> "
            ;;
          $ZVM_MODE_VISUAL)
            POSH_VI_MODE=">> "
            ;;
          $ZVM_MODE_VISUAL_LINE)
            POSH_VI_MODE=">> "
            ;;
          $ZVM_MODE_REPLACE)
            POSH_VI_MODE="{} "
            ;;
          esac
          _omp_redraw-prompt
        }

        function zvm_vi_yank() {
          zvm_yank
          echo ''${CUTBUFFER} | pbcopy
          zvm_exit_visual_mode
        }
        function zvm_vi_delete() {
          zvm_replace_selection
          echo ''${CUTBUFFER} | pbcopy
          zvm_exit_visual_mode ''\${"1:-true"}
        }
        [[ -n "$SYSINIT_DEBUG" ]] && zprof
      '')
    ];
  };
}
