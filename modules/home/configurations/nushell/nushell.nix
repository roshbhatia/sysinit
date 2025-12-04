{
  config,
  lib,
  values,
  ...
}:
let
  shell = import ../../../lib/shell { inherit lib; };
  themes = import ../../../lib/theme { inherit lib; };

  validatedTheme = themes.validateThemeConfig values.theme;
  palette = themes.getThemePalette validatedTheme.colorscheme validatedTheme.variant;
  colors = themes.getUnifiedColors palette;

  sharedEnv = shell.env {
    inherit config colors;
    appTheme = themes.getAppTheme "vivid" validatedTheme.colorscheme validatedTheme.variant;
  };
  sharedAliases = shell.aliases;

  completions = shell.stripHeaders ./integrations/completions.nu;
  prompt = shell.stripHeaders ./ui/prompt.nu;
  wezterm = shell.stripHeaders ./ui/wezterm.nu;
in
{
  programs.nushell = {
    enable = true;

    shellAliases = lib.foldl' (acc: aliases: acc // aliases) { } (
      lib.flatten [
        sharedAliases.navigation
        sharedAliases.listing
        sharedAliases.tools
      ]
    );

    environmentVariables = {
      LANG = sharedEnv.LANG;
      LC_ALL = sharedEnv.LC_ALL;
      SUDO_EDITOR = sharedEnv.SUDO_EDITOR;
      VISUAL = sharedEnv.VISUAL;
      EDITOR = sharedEnv.EDITOR;
      GIT_DISCOVERY_ACROSS_FILESYSTEM = sharedEnv.GIT_DISCOVERY_ACROSS_FILESYSTEM;
      COLIMA_HOME = sharedEnv.COLIMA_HOME;
      FZF_DEFAULT_COMMAND = sharedEnv.FZF_DEFAULT_COMMAND;
      FZF_DEFAULT_OPTS = sharedEnv.FZF_DEFAULT_OPTS;
      VIVID_THEME = sharedEnv.VIVID_THEME;
      ZK_NOTEBOOK_DIR = sharedEnv.ZK_NOTEBOOK_DIR;
    };

    settings = {
      show_banner = false;
      edit_mode = "vi";
      completion = {
        case_sensitive = false;
        quick = true;
        partial = true;
        algorithm = "fuzzy";
        external = {
          enable = false;
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
        file_format = "plaintext";
        isolation = false;
      };
    };

    extraConfig = ''
      $env.config.keybindings = [
        {
          name: completion_menu
          modifier: none
          keycode: tab
          mode: [emacs vi_normal vi_insert]
          event: {
            until: [
              { send: menu name: completion_menu }
              { send: menunext }
              { edit: complete }
            ]
          }
        }
      ]
    ''
    + "\n\n${completions}\n"
    + "\n${prompt}\n"
    + "\n${wezterm}\n";

    envFile.text = ''
      # Shortcuts - define as functions in env file
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: value: "def --env ${name} [] { ${value} }") sharedAliases.shortcuts
      )}
    '';
  };
}
