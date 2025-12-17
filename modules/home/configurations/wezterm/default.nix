{
  config,
  values,
  utils,
  ...
}:

let
  inherit (utils.theme) generateAppJSON;

  themeConfig = values.theme // {
    presets = values.theme.presets or [ ];
    overrides = values.theme.overrides or { };
  };

  inherit (config.lib.file) mkOutOfStoreSymlink;
  sysinitPath = builtins.getEnv "PWD";
  wezConfigPath = "${sysinitPath}/modules/home/configurations/wezterm";
in
{
  stylix.targets.wezterm.enable = false;

  xdg.configFile."wezterm/wezterm.lua".source = mkOutOfStoreSymlink "${wezConfigPath}/wezterm.lua";

  xdg.configFile."wezterm/lua".source = mkOutOfStoreSymlink "${wezConfigPath}/lua";

  xdg.configFile."wezterm/theme_config.json".text = builtins.toJSON (
    generateAppJSON "wezterm" themeConfig
  );

  xdg.configFile."wezterm/colors".source = ./colors;
}
