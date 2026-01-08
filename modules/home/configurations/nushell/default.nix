{
  config,
  lib,
  values,
  pkgs,
  ...
}:

let
  shell = import ../../../shared/lib/shell { inherit lib; };
  themes = import ../../../shared/lib/theme { inherit lib; };
  paths_lib = import ../../../shared/lib/paths { inherit config lib; };

  validatedTheme = values.theme;
  appTheme = themes.getAppTheme "vivid" validatedTheme.colorscheme validatedTheme.variant;
  sharedAliases = shell.aliases;
  pathsList = paths_lib.getAllPaths config.home.username config.home.homeDirectory;

  nushellBuiltins = [
    "find"
    "watch"
    "diff"
    "grep"
  ];
  toolAliases = builtins.removeAttrs sharedAliases.tools nushellBuiltins;
in
{
  programs.nushell = {
    enable = true;
    package = pkgs.nushell.override {
      additionalFeatures = p: p ++ [ "mcp" ];
    };

    shellAliases = lib.mkForce (
      toolAliases // sharedAliases.listing // sharedAliases.navigation // sharedAliases.shortcuts
    );

    settings = {
      show_banner = false;
      edit_mode = "vi";
      completions = {
        case_sensitive = false;
        quick = true;
        partial = true;
        algorithm = "fuzzy";
      };
      cursor_shape = {
        vi_insert = "line";
        vi_normal = "block";
      };
      history = {
        max_size = 50000;
        sync_on_enter = true;
        file_format = "sqlite";
        isolation = false;
      };
    };

    environmentVariables = {
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      VISUAL = "nvim";
      EDITOR = "nvim";
      SUDO_EDITOR = "nvim";
      GIT_DISCOVERY_ACROSS_FILESYSTEM = "1";
      FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules";
      VIVID_THEME = appTheme;
    };

    extraEnv = ''
      use std/util "path add"

      $env.XDG_CACHE_HOME = "${config.xdg.cacheHome}"
      $env.XDG_CONFIG_HOME = "${config.xdg.configHome}"
      $env.XDG_DATA_HOME = "${config.xdg.dataHome}"
      $env.XDG_STATE_HOME = "${config.xdg.stateHome}"
      $env.XCA = "${config.xdg.cacheHome}"
      $env.XCO = "${config.xdg.configHome}"
      $env.XDA = "${config.xdg.dataHome}"
      $env.XST = "${config.xdg.stateHome}"

      ${lib.concatMapStringsSep "\n" (path: "path add \"${path}\"") pathsList}
    '';

    extraConfig = ''
      use std/dirs shells-aliases *

      $env.NU_LIB_DIRS = (
        $nu.env.NU_LIB_DIRS 
        | split row (char esac) 
        | prepend "${config.xdg.configHome}/nushell"
      )

      use lib/init.nu *

      oh-my-posh init nu --config ${config.xdg.configHome}/oh-my-posh/themes/sysinit.omp.json
    '';
  };

  home.file = {
    "${config.xdg.configHome}/nushell/lib/keybindings.nu".source = ./ui/keybindings.nu;
    "${config.xdg.configHome}/nushell/lib/wezterm.nu".source = ./integrations/wezterm.nu;
    "${config.xdg.configHome}/nushell/lib/zoxide.nu".source = ./integrations/zoxide.nu;
    "${config.xdg.configHome}/nushell/lib/k8s.nu".source = ./integrations/k8s.nu;
    "${config.xdg.configHome}/nushell/lib/completers.nu".source = ./core/completers.nu;
    "${config.xdg.configHome}/nushell/lib/hooks.nu".source = ./core/hooks.nu;
    "${config.xdg.configHome}/nushell/lib/init.nu".source = ./lib/init.nu;
  };
}
