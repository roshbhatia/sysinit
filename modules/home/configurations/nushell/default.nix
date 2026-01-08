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
  toolAliases = builtins.removeAttrs sharedAliases.tools nushellBuiltins // {
    cat = "bat -pp";
  };
  listingAliases = builtins.removeAttrs sharedAliases.listing [ "ls" ];

  keybindingsConfig = builtins.readFile ./ui/keybindings.nu;
  weztermConfig = builtins.readFile ./integrations/wezterm.nu;
  zoxideConfig = builtins.readFile ./integrations/zoxide.nu;
  k8sConfig = builtins.readFile ./integrations/k8s.nu;
  completersConfig = builtins.readFile ./core/completers.nu;
  hooksConfig = builtins.readFile ./core/hooks.nu;
in
{
  programs.nushell = {
    enable = true;
    package = pkgs.nushell.override {
      additionalFeatures = p: p ++ [ "mcp" ];
    };

    shellAliases = lib.mkForce (
      toolAliases
      // listingAliases
      // {
        sg = "ast-grep";
      }
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
        vi_insert = "underscore";
        vi_normal = "block";
      };
      history = {
        max_size = 50000;
        sync_on_enter = true;
        file_format = "sqlite";
        isolation = false;
      };
    };

    extraEnv = ''
      use std/util "path add"

      $env.LANG = "en_US.UTF-8"
      $env.LC_ALL = "en_US.UTF-8"
      $env.VISUAL = "nvim"
      $env.EDITOR = "nvim"
      $env.SUDO_EDITOR = "nvim"
      $env.config.buffer_editor= "nvim"

      $env.XDG_CACHE_HOME = "${config.xdg.cacheHome}"
      $env.XDG_CONFIG_HOME = "${config.xdg.configHome}"
      $env.XDG_DATA_HOME = "${config.xdg.dataHome}"
      $env.XDG_STATE_HOME = "${config.xdg.stateHome}"
      $env.XCA = "${config.xdg.cacheHome}"
      $env.XCO = "${config.xdg.configHome}"
      $env.XDA = "${config.xdg.dataHome}"
      $env.XST = "${config.xdg.stateHome}"

      $env.GIT_DISCOVERY_ACROSS_FILESYSTEM = "1"
      $env.FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules"
      $env.VIVID_THEME = "${appTheme}"

      ${lib.concatMapStringsSep "\n" (path: "path add \"${path}\"") pathsList}

      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: value:
          let
            nuValue = lib.replaceStrings [ "$HOME" ] [ "$env.HOME" ] value;
          in
          "def --env ${name} [] { ${nuValue} }"
        ) (sharedAliases.navigation // sharedAliases.shortcuts)
      )}
    '';

    extraConfig = ''
      ${keybindingsConfig}
      ${weztermConfig}
      ${zoxideConfig}
      ${k8sConfig}
      ${completersConfig}
      ${hooksConfig}
      use std/dirs shells-aliases *

      oh-my-posh init nu --config ${config.xdg.configHome}/oh-my-posh/themes/sysinit.omp.json
    '';
  };
}
