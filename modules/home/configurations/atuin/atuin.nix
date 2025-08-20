{
  values,
  utils,
  ...
}:

let
  inherit (utils.themeHelper) mkThemedConfig;
  themeCfg = mkThemedConfig values "atuin" { };
  atuinTheme = themeCfg.appTheme;
in

{
  programs.atuin = {
    enable = true;

    enableZshIntegration = false;

    enableNushellIntegration = false;

    settings = {
      update_check = false;
      inline_height = 15;
      show_help = false;
      show_tabs = false;
      enter_accept = true;
      invert = true;
      keymap_mode = "vim-normal";
      show_preview = false;
      style = "compact";
      theme = {
        name = atuinTheme;
      };

      history_filter = [
        "with-env .*atuin search.*"
      ];
    };
  };

  xdg.configFile = utils.themeHelper.deployThemeFiles values {
    app = "atuin";
    themeDir = ./themes;
    targetPath = "atuin/themes";
    fileExtension = "toml";
  };
}
