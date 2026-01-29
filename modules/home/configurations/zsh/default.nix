{
  config,
  lib,
  pkgs,
  values,
  ...
}:
let
  themes = import ../../../shared/lib/theme.nix { inherit lib; };
  shellUtils = import ../../../shared/lib/shell.nix { inherit lib; };

  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  colors = themes.getUnifiedColors palette;

  systemPaths = {
    nix = [
      "/nix/var/nix/profiles/default/bin"
      "/etc/profiles/per-user/${config.home.username}/bin"
      "/run/wrappers/bin"
      "/run/current-system/sw/bin"
    ];
    system = [
      "/opt/homebrew/bin"
      "/opt/homebrew/opt/libgit2@1.8/bin"
      "/opt/homebrew/sbin"
      "/usr/bin"
      "/usr/local/opt/cython/bin"
      "/usr/sbin"
    ];
    user = [
      "${config.home.homeDirectory}/.cargo/bin"
      "${config.home.homeDirectory}/.krew/bin"
      "${config.home.homeDirectory}/.local/bin"
      "${config.home.homeDirectory}/.npm-global/bin"
      "${config.home.homeDirectory}/.npm-global/bin/yarn"
      "${config.home.homeDirectory}/.rvm/bin"
      "${config.home.homeDirectory}/.uv/bin"
      "${config.home.homeDirectory}/.yarn/bin"
      "${config.home.homeDirectory}/.yarn/global/node_modules/.bin"
      "${config.home.homeDirectory}/bin"
      "${config.home.homeDirectory}/go/bin"
    ];
    xdg = [
      "${config.home.homeDirectory}/.config/.cargo/bin"
      "${config.home.homeDirectory}/.config/yarn/global/node_modules/.bin"
      "${config.home.homeDirectory}/.config/zsh/bin"
      "${config.home.homeDirectory}/.local/share/.npm-packages/bin"
    ];
  };

  pathsList = systemPaths.nix ++ systemPaths.system ++ systemPaths.user ++ systemPaths.xdg;

  coreInit = shellUtils.stripHeaders ./core/init.zsh;
  corePath = shellUtils.stripHeaders ./core/path.zsh;
  env = shellUtils.stripHeaders ./system/env.zsh;
  integrationsCompletions = shellUtils.stripHeaders ./integrations/completions.zsh;
  integrationsExtras = shellUtils.stripHeaders ./integrations/extras.zsh;
  libCache = shellUtils.stripHeaders ./lib/cache.zsh;
  uiPrompt = shellUtils.stripHeaders ./ui/prompt.zsh;

  # Only fetch wezterm integration on darwin (where it's commonly used)
  # This avoids evaluation issues during nix flake check on NixOS
  integrationsWezterm =
    if pkgs.stdenv.isDarwin then
      builtins.readFile (
        pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/wezterm/wezterm/refs/heads/main/assets/shell-integration/wezterm.sh";
          sha256 = "sha256-GQGDcxMHv04TEaFguHXi0dOoOX5VUR2He4XjTxPuuaw=";
        }
      )
    else
      "";
in
{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;

    autocd = true;

    # Disable built-in zsh plugins - using custom oh-my-zsh and fzf-based alternatives for better performance
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
      ZVM_INSERT_MODE_CURSOR = "be";
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
      (lib.mkOrder 200 ''
        ${coreInit}
      '')

      (lib.mkOrder 300 "${corePath}\n\n# Add configured paths\npath.add.bulk \\\n  ${
        lib.concatStringsSep " \\\n          " (map (path: "\"${path}\"") pathsList)
      }\n")

      (lib.mkOrder 400 ''
        ${libCache}
      '')

      (lib.mkOrder 500 ''
        mkdir -p ${config.xdg.cacheHome}/zsh
        autoload -Uz compinit
        compinit -C -d "${config.xdg.cacheHome}/zsh/zcompdump/.zcompdump"

        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path "${config.xdg.cacheHome}/zsh/zcompcache"
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
        zstyle ':completion:*' menu no

        zstyle ':completion:*' group-name '''
        zstyle ':completion:*:descriptions' format '[%d]'
        zstyle ':completion:*:git-checkout:*' sort false

        zstyle ':fzf-tab:*' use-fzf-default-opts yes
        zstyle ':fzf-tab:*' fzf-pad 4
        zstyle ':fzf-tab:*' single-group color header
        zstyle ':fzf-tab:*' show-group full
        zstyle ':fzf-tab:*' fzf-flags --gutter=" " --preview-window=right:50%:wrap
        zstyle ':fzf-tab:*' query-string ""
        zstyle ':fzf-tab:*' continuous-trigger "/"
        zstyle ':fzf-tab:*' fzf-bindings "tab:down" "btab:up" "enter:accept"

        zstyle ':fzf-tab:complete:(bat|cat|cd|chafa|eza|ls|nvim|v|vi|vim):*' \
          fzf-preview 'fzf-preview "''${realpath:-$word}"'
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
    ];
  };
}
