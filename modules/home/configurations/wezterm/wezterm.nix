{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  inherit (utils.themes) generateAppJSON;

  # Pass entire theme config to enable appearance-to-variant derivation
  # Note: using 'or' pattern to provide defaults for optional fields
  themeConfig = values.theme // {
    presets = values.theme.presets or [ ];
    overrides = values.theme.overrides or { };
  };

  mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
in
{
  xdg.configFile."wezterm/wezterm.lua".source =
    mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/wezterm/wezterm.lua";

  xdg.configFile."wezterm/lua".source =
    mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/wezterm/lua";

  xdg.configFile."wezterm/theme_config.json".text = builtins.toJSON (
    generateAppJSON "wezterm" themeConfig
  );

  xdg.configFile."wezterm/core_config.json".text = builtins.toJSON {
    wezterm_entrypoint = values.wezterm.shell or "zsh";
  };
}
