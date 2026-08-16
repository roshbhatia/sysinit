{
  config,
  lib,
  pkgs,
  values ? { },
  ...
}:
let
  themeLib = import ../../../shared/theme-colors.nix { inherit lib; };
  themeColors = themeLib.colorsOf config;
  shellUtils = import ../../../lib/shell.nix { inherit lib; };
  paths_lib = import ../../../lib/paths.nix { inherit config lib; };

  pathsList = paths_lib.getAllPaths config.home.username config.home.homeDirectory;

  coreInit = shellUtils.stripHeaders ./core/init.zsh;
  corePath = shellUtils.stripHeaders ./core/path.zsh;
  coreCompinit = shellUtils.stripHeaders ./core/compinit.zsh;
  coreZshenv = shellUtils.stripHeaders ./core/zshenv.zsh;
  coreAgentGlob = shellUtils.stripHeaders ./core/agent-glob.zsh;
  corePathApply = shellUtils.stripHeaders ./core/path-apply.zsh;
  env = shellUtils.stripHeaders ./system/env.zsh;
  integrationsCompletions = shellUtils.stripHeaders ./integrations/completions.zsh;
  integrationsExtras = shellUtils.stripHeaders ./integrations/extras.zsh;
  seshyWezterm = shellUtils.stripHeaders ./integrations/seshy-wezterm.zsh;
  sshMux = shellUtils.stripHeaders ./integrations/ssh-mux.zsh;
  askCapture = shellUtils.stripHeaders ./integrations/ask.zsh;
  libCache = shellUtils.stripHeaders ./lib/cache.zsh;
in
{
  programs.zsh = {
    enable = true;

    dotDir = "${config.xdg.configHome}/zsh";

    envExtra = coreAgentGlob;

    autocd = true;
    enableCompletion = false;

    history = {
      path = "${config.home.homeDirectory}/.zsh_history";
      size = 1000000;
      save = 1000000;
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
      ZVM_SYSTEM_CLIPBOARD_ENABLED = "true";
      ZVM_INSERT_MODE_CURSOR = "be";
      ZVM_VI_HIGHLIGHT_BACKGROUND = "#${themeColors.base05}";
      ZVM_VI_HIGHLIGHT_FOREGROUND = "#${themeColors.base0D}";
    }
    // (values.environment or { });

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
        ${coreZshenv}
      '')

      (lib.mkOrder 200 ''
        ${coreInit}
      '')

      (lib.mkOrder 300 ''
        ${corePath}

        SYSINIT_PATHS=(
          ${lib.concatStringsSep "\n          " (map (path: "\"${path}\"") pathsList)}
        )
        ${corePathApply}
      '')

      (lib.mkOrder 400 ''
        ${libCache}
      '')

      (lib.mkOrder 500 ''
        ZSH_CACHE_DIR="${config.xdg.cacheHome}/zsh"
        ${coreCompinit}
      '')

      (lib.mkOrder 600 ''
        ${integrationsCompletions}
        ${integrationsExtras}
        ${env}
      '')

      (lib.mkOrder 700 ''
        ${seshyWezterm}
        ${sshMux}
        ${askCapture}
      '')
    ];
  };
}
