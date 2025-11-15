{
  values,
  utils,
  ...
}:

let
  inherit (utils.theme) mkThemedConfig;

  themeCfg = mkThemedConfig values "atuin" { };
  atuinTheme = themeCfg.appTheme;
in
{
  programs.atuin = {
    enable = true;
    # This is enabled manually
    enableZshIntegration = false;

    settings = {
      update_check = false;
      inline_height = 15;
      show_help = false;
      show_tabs = false;
      enter_accept = true;
      invert = true;
      keymap_mode = "vim-normal";
      show_preview = true;
      style = "compact";
      theme = {
        name = atuinTheme;
      };

      history_filter = [
        "with-env .*atuin search.*"
      ];
    };
  };

  xdg.configFile = utils.theme.deployThemeFiles values {
    themeDir = ./themes;
    targetPath = "atuin/themes";
    fileExtension = "toml";
  };
}
