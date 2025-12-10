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

  validatedTheme = themes.validateThemeConfig values.theme;
  appTheme = themes.getAppTheme "vivid" validatedTheme.colorscheme validatedTheme.variant;
  palette = themes.getThemePalette validatedTheme.colorscheme validatedTheme.variant;
  colors = themes.getUnifiedColors palette;

  pathsList = paths_lib.getAllPaths config.home.username config.home.homeDirectory;

  # Core modules - loaded earliest
  coreInit = shell.stripHeaders ./core/init.zsh;
  corePath = shell.stripHeaders ./core/path.zsh;

  # Library modules - utilities available to other scripts
  libCache = shell.stripHeaders ./lib/cache.zsh;
  libFunctions = shell.stripHeaders ./lib/functions.zsh;

  # Integration modules
  integrationsWezterm = shell.stripHeaders ./integrations/wezterm.zsh;
  integrationsCompletions = shell.stripHeaders ./integrations/completions.zsh;
  integrationsTools = shell.stripHeaders ./integrations/tools.zsh;
  integrationsExtras = shell.stripHeaders ./integrations/extras.zsh;

  # UI modules - loaded last
  uiPrompt = shell.stripHeaders ./ui/prompt.zsh;
  uiVimMode = shell.stripHeaders ./ui/vim-mode.zsh;

  # Environment (kept separate due to potential secrets)
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

      FZF_DEFAULT_OPTS = builtins.concatStringsSep " " [
        "--bind='resize:refresh-preview'"
        "--color=bg+:-1,bg:-1,spinner:${colors.accent.primary},hl:${colors.accent.primary}"
        "--color=border:${colors.background.overlay},label:${colors.foreground.primary}"
        "--color=fg:${colors.foreground.primary},header:${colors.accent.primary},info:${colors.foreground.muted},pointer:${colors.accent.primary}"
        "--color=marker:${colors.accent.primary},fg+:${colors.foreground.primary},prompt:${colors.accent.primary},hl+:${colors.accent.primary}"
        "--color=preview-bg:-1,query:${colors.foreground.primary}"
        "--cycle"
        "--gutter=' '"
        "--height=30"
        "--highlight-line"
        "--ignore-case"
        "--info=inline"
        "--input-border=rounded"
        "--layout=reverse"
        "--list-border=rounded"
        "--no-scrollbar"
        "--pointer='>'"
        "--preview 'fzf-preview {}'"
        "--preview-border=rounded"
        "--prompt='>> '"
        "--scheme='history'"
        "--style='minimal'"
      ];

      VIVID_THEME = appTheme;

      ZK_NOTEBOOK_DIR = "$HOME/github/personal/roshbhatia/zeek/notes";
    };

    plugins = [
      # evalcache first - core infra used by other init scripts
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
      # zsh-vi-mode last - handles keybindings after other plugins loaded
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
      # ============================================================
      # ORDER 100: Debug profiling (earliest)
      # ============================================================
      (lib.mkOrder 100 ''
        [[ -n "$SYSINIT_DEBUG" ]] && zmodload zsh/zprof
      '')

      # ============================================================
      # ORDER 200: Core initialization
      # ============================================================
      (lib.mkOrder 200 ''
        ${coreInit}
      '')

      # ============================================================
      # ORDER 300: PATH management
      # ============================================================
      (lib.mkOrder 300 ''
        ${corePath}

        # Add configured paths
        path.add.bulk \
          ${lib.concatStringsSep " \\\n          " (map (path: "\"${path}\"") pathsList)}
      '')

      # ============================================================
      # ORDER 400: Library utilities (cache, functions)
      # ============================================================
      (lib.mkOrder 400 ''
        ${libCache}
        ${libFunctions}
      '')

      # ============================================================
      # ORDER 500: Completion system
      # ============================================================
      (lib.mkOrder 500 ''
        mkdir -p ${config.xdg.cacheHome}/zsh
        autoload -Uz compinit
        if [[ -n ${config.xdg.cacheHome}/zsh/zcompdump/.zcompdump(#qN.mh+24) ]]; then
          compinit -d "${config.xdg.cacheHome}/zsh/zcompdump/.zcompdump"
        else
          compinit -C -d "${config.xdg.cacheHome}/zsh/zcompdump/.zcompdump"
        fi

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

        compdef _ls ls
      '')

      # ============================================================
      # ORDER 600: Integrations
      # ============================================================
      (lib.mkOrder 600 ''
        ${integrationsWezterm}
        ${integrationsTools}
        ${integrationsCompletions}
        ${integrationsExtras}
        ${env}
      '')

      # ============================================================
      # ORDER 700: UI (prompt, vim-mode)
      # ============================================================
      (lib.mkOrder 700 ''
        ${uiPrompt}
        ${uiVimMode}
      '')

      # ============================================================
      # ORDER 900: Debug profiling output (latest)
      # ============================================================
      (lib.mkOrder 900 ''
        [[ -n "$SYSINIT_DEBUG" ]] && zprof
      '')
    ];
  };
}
