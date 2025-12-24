{
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
in
{
  stylix.targets.wezterm.enable = false;

  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;

  xdg.configFile."wezterm/lua".source = ./lua;

  xdg.configFile."wezterm/theme_config.json".text = builtins.toJSON (
    generateAppJSON "wezterm" themeConfig
  );
}
