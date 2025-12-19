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
  kubernetesAliases = sharedAliases.kubernetes;

  promptConfig = builtins.readFile ./ui/prompt.nu;
  keybindingsConfig = builtins.readFile ./ui/keybindings.nu;
  wezTermConfig = builtins.readFile ./integrations/wezterm.nu;
  macchinaConfig = builtins.readFile ./integrations/macchina.nu;
  nixConfig = builtins.readFile ./integrations/nix.nu;
  completionsConfig = builtins.readFile ./integrations/completions.nu;
  functionsConfig = builtins.readFile ./core/functions.nu;
in
{
  stylix.targets.nushell.enable = true;

  programs.nushell = {
    enable = true;
    package = pkgs.nushell.override {
      additionalFeatures = p: p ++ [ "mcp" ];
    };

    shellAliases = lib.mkForce (toolAliases // listingAliases // kubernetesAliases);

    settings = {
      show_banner = false;
      edit_mode = "vi";
      completions = {
        case_sensitive = false;
        quick = true;
        partial = true;
        algorithm = "fuzzy";
        external = {
          enable = true;
          max_results = 100;
        };
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

    environmentVariables = {
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      EDITOR = "nvim";
      VISUAL = "nvim";
      SUDO_EDITOR = "nvim";
      GIT_DISCOVERY_ACROSS_FILESYSTEM = "1";
      COLIMA_HOME = "${config.xdg.configHome}/colima";
      FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules";
      VIVID_THEME = appTheme;
      OMP_CONFIG = "${config.xdg.configHome}/oh-my-posh/themes/sysinit.omp.json";
    };

    extraConfig = ''
      ${promptConfig}
      ${keybindingsConfig}
      ${wezTermConfig}
      ${macchinaConfig}
      ${nixConfig}
      ${completionsConfig}
      ${functionsConfig}

      use std/util "path add"
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
  };
}
