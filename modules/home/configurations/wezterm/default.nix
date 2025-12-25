{
  values,
  ...
}:

{
  stylix.targets.wezterm.enable = true;

  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;

  xdg.configFile."wezterm/lua".source = ./lua;

  xdg.configFile."wezterm/config.json".text = builtins.toJSON {
    font = {
      inherit (values.theme.font) monospace;
    };
  };
}
