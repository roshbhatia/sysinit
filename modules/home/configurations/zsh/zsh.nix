{
  config,
  lib,
  pkgs,
  values,
  ...
}:
let
  shell = import ../../../lib/shell { inherit lib; };
  themes = import ../../../lib/theme { inherit lib; };
  paths_lib = import ../../../lib/paths { inherit config lib; };
  appTheme = themes.getAppTheme "vivid" values.theme.colorscheme values.theme.variant;
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  colors = themes.getUnifiedColors palette;

  pathsList = paths_lib.getAllPaths config.home.username config.home.homeDirectory;

  wezterm = shell.stripHeaders ./ui/wezterm.sh;
  prompt = shell.stripHeaders ./ui/prompt.sh;

  completions = shell.stripHeaders ./integrations/completions.sh;

  kubectl = shell.stripHeaders ./tools/kubectl.sh;

  env = shell.stripHeaders ./system/env.sh;
  extras = shell.stripHeaders ./system/extras.sh;
in
{
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

    shellAliases = {
      "....." = "cd ../../../..";
      "...." = "cd ../../..";
      "..." = "cd ../..";
      ".." = "cd ..";
      "~" = "cd ~";

      code = "code-insiders";
      c = "code-insiders";
      v = "nvim";

      kubectl = "kubecolor";
      tf = "terraform";
      y = "yazi";
      g = "git";
      gg = "lazygit";

      l = "eza --icons=always -1";
      la = "eza --icons=always -1 -a";
      ll = "eza --icons=always -1 -a";
      ls = "eza";
      lt = "eza --icons=always -1 -a -T --git-ignore --ignore-glob='.git'";

      sudo = "sudo -E";
      diff = "diff --color";
      grep = "grep -s --color=auto";
      watch = "KUBECOLOR_FORCE_COLORS=auto watch --color --no-title";
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
        "--color=bg+:-1,bg:-1,spinner:${colors.accent.primary},hl:${colors.accent.primary}"
        "--color=border:${colors.background.overlay},label:${colors.foreground.primary}"
        "--color=fg:${colors.foreground.primary},header:${colors.accent.primary},info:${colors.foreground.muted},pointer:${colors.accent.primary}"
        "--color=marker:${colors.accent.primary},fg+:${colors.foreground.primary},prompt:${colors.accent.primary},hl+:${colors.accent.primary}"
        "--color=preview-bg:-1,query:${colors.foreground.primary}"
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
      SYSINIT_NVIM_DASH_ASCII_PATH = "${config.xdg.configHome}/macchina/themes/rosh.ascii";
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
        name = "fzf-tab";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "fc6f0dcb2d5e41a4a685bfe9af2f2393dc39f689";
          sha256 = "sha256-1g3kToboNGXNJTd+LEIB/j76VgPdYqG2PNs3u6Zke9s=";
        };
        file = "fzf-tab.plugin.zsh";
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
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5";
          sha256 = "1885w3crr503h5n039kmg199sikb1vw1fvaidwr21sj9mn01fs9a";
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

        stty stop undef
        setopt COMBINING_CHARS
        setopt PROMPT_SUBST
        PROMPT='%~%'
        RPS1=""

      '')

      (lib.mkOrder 550 ''
        mkdir -p ${config.xdg.cacheHome}/zsh
        autoload bashcompinit && bashcompinit
        autoload -Uz compinit
        if [[ -n ${config.xdg.cacheHome}/zsh/zcompdump/.zcompdump(#qN.mh+24) ]]; then
          compinit -d "${config.xdg.cacheHome}/zsh/zcompdump/.zcompdump";
        else
          compinit -C -d "${config.xdg.cacheHome}/zsh/zcompdump/.zcompdump";
        fi

        zstyle ':completion:*:git-checkout:*' sort false
        zstyle ':completion:*:descriptions' format '[%d]'
        zstyle ':completion:*' list-colors ''\${(s.:.)LS_COLORS}
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
        zstyle ':completion:*:complete:*' use-cache on
        zstyle ':completion:*' menu no


        zstyle ':fzf-tab:*' use-fzf-default-opts yes
        zstyle ':fzf-tab:*' fzf-pad 4
        zstyle ':fzf-tab:*' single-group color header
        zstyle ':fzf-tab:*' show-group full


        zstyle ':fzf-tab:*' query-string ""
        zstyle ':fzf-tab:*' continuous-trigger "/"
        zstyle ':fzf-tab:*' fzf-bindings "tab:down" "btab:up"


        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'fzf-preview "$realpath"'
        zstyle ':fzf-tab:complete:cat:*' fzf-preview 'fzf-preview "$word"'
        zstyle ':fzf-tab:complete:bat:*' fzf-preview 'fzf-preview "$word"'
        zstyle ':fzf-tab:complete:nvim:*' fzf-preview 'fzf-preview "$word"'
        zstyle ':fzf-tab:complete:vim:*' fzf-preview 'fzf-preview "$word"'
        zstyle ':fzf-tab:complete:vi:*' fzf-preview 'fzf-preview "$word"'
        zstyle ':fzf-tab:complete:v:*' fzf-preview 'fzf-preview "$word"'

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

        if [[ -n "$WEZTERM_UNIX_SOCKET" ]]; then
          ${wezterm}
        fi

        ${kubectl}
        ${env}
        ${extras}
        ${completions}
        ${prompt}

      ''

      (lib.mkAfter ''
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

