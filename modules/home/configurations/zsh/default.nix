{
  config,
  lib,
  pkgs,
  values,
  ...
}:
let
  shell = import ../../../shared/lib/shell { inherit lib; };
  themes = import ../../../shared/lib/theme { inherit lib; };
  paths_lib = import ../../../shared/lib/paths { inherit config lib; };

  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  colors = themes.getUnifiedColors palette;

  pathsList = paths_lib.getAllPaths config.home.username config.home.homeDirectory;

  coreInit = shell.stripHeaders ./core/init.zsh;
  corePath = shell.stripHeaders ./core/path.zsh;

  libCache = shell.stripHeaders ./lib/cache.zsh;

  integrationsWezterm = builtins.readFile (
    pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/wezterm/wezterm/refs/heads/main/assets/shell-integration/wezterm.sh";
      sha256 = "sha256-GQGDcxMHv04TEaFguHXi0dOoOX5VUR2He4XjTxPuuaw=";
    }
  );
  integrationsCompletions = shell.stripHeaders ./integrations/completions.zsh;
  integrationsExtras = shell.stripHeaders ./integrations/extras.zsh;

  uiPrompt = shell.stripHeaders ./ui/prompt.zsh;

  env = shell.stripHeaders ./system/env.sh;
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

    sessionVariables = {
      ZSH_EVALCACHE_DIR = "${config.xdg.dataHome}/zsh/evalcache";
      ZSH_AUTOSUGGEST_USE_ASYNC = 1;
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = 20;
      ZSH_AUTOSUGGEST_MANUAL_REBIND = 1;

      ZVM_LINE_INIT_MODE = "i";
      ZVM_SYSTEM_CLIPBOARD_ENABLED = true;
      ZVM_VI_HIGHLIGHT_BACKGROUND = colors.foreground.primary;
      ZVM_VI_HIGHLIGHT_FOREGROUND = colors.accent.primary;
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
        name = "zsh-vi-mode";
        src = pkgs.fetchFromGitHub {
          owner = "jeffreytse";
          repo = "zsh-vi-mode";
          rev = "v0.11.0";
          sha256 = "sha256-xbchXJTFWeABTwq6h4KWLh+EvydDrDzcY9AQVK65RS8=";
        };
        file = "zsh-vi-mode.plugin.zsh";
      }
    ];

    initContent = lib.mkMerge [
      (lib.mkOrder 100 ''
        [[ -n "$SYSINIT_DEBUG" ]] && zmodload zsh/zprof
      '')

      (lib.mkOrder 200 ''
        ${coreInit}
      '')

      (lib.mkOrder 300 ''
        ${corePath}

        # Add configured paths
        path.add.bulk \
          ${lib.concatStringsSep " \\\n          " (map (path: "\"${path}\"") pathsList)}
      '')

      (lib.mkOrder 400 ''
        ${libCache}
      '')

      (lib.mkOrder 500 ''
        mkdir -p ${config.xdg.cacheHome}/zsh
        autoload -Uz compinit
        compinit -C -d "${config.xdg.cacheHome}/zsh/zcompdump/.zcompdump"

        # Completion styles
        zstyle ':completion:*:git-checkout:*' sort false
        zstyle ':completion:*:descriptions' format '[%d]'
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
        zstyle ':completion:*:complete:*' use-cache on
        zstyle ':completion:*' menu no

        # fzf-tab styles
        zstyle ':fzf-tab:*' use-fzf-default-opts yes
        zstyle ':fzf-tab:*' fzf-pad 4
        zstyle ':fzf-tab:*' single-group color header
        zstyle ':fzf-tab:*' show-group full
        zstyle ':fzf-tab:*' fzf-flags --gutter=" "
        zstyle ':fzf-tab:*' query-string ""
        zstyle ':fzf-tab:*' continuous-trigger "/"
        zstyle ':fzf-tab:*' fzf-bindings "tab:down" "btab:up" "enter:accept"

        # fzf-tab previews
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'word="$word" realpath="$realpath" fzf-preview'
        zstyle ':fzf-tab:complete:cat:*' fzf-preview 'word="$word" realpath="$realpath" fzf-preview'
        zstyle ':fzf-tab:complete:bat:*' fzf-preview 'word="$word" realpath="$realpath" fzf-preview'
        zstyle ':fzf-tab:complete:nvim:*' fzf-preview 'word="$word" realpath="$realpath" fzf-preview'
        zstyle ':fzf-tab:complete:vim:*' fzf-preview 'word="$word" realpath="$realpath" fzf-preview'
        zstyle ':fzf-tab:complete:vi:*' fzf-preview 'word="$word" realpath="$realpath" fzf-preview'
        zstyle ':fzf-tab:complete:v:*' fzf-preview 'word="$word" realpath="$realpath" fzf-preview'
        zstyle ':fzf-tab:complete:ls:*' fzf-preview 'word="$word" realpath="$realpath" fzf-preview'
        zstyle ':fzf-tab:complete:eza:*' fzf-preview 'word="$word" realpath="$realpath" fzf-preview'
      '')

      (lib.mkOrder 600 ''
        ${integrationsWezterm}
        ${integrationsCompletions}
        ${integrationsExtras}
        ${env}
      '')

      (lib.mkOrder 899 ''
        ${uiPrompt}
      '')

      (lib.mkOrder 900 ''
        [[ -n "$SYSINIT_DEBUG" ]] && zprof
      '')
    ];
  };
}
