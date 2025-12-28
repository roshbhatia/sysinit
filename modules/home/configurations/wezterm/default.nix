{
  values,
  lib,
  ...
}:

let
  themeNames = import ../../../shared/lib/theme/adapters/theme-names.nix { inherit lib; };
  themeName = themeNames.getWeztermTheme values.theme.colorscheme values.theme.variant;
  configGen = import ../../../shared/lib/config-gen.nix { inherit lib; };
in
{
  stylix.targets.wezterm.enable = false;

  xdg.configFile = {
    "wezterm/wezterm.lua".source = ./wezterm.lua;
    "wezterm/lua".source = ./lua;
    "wezterm/config.json".text = configGen.toJsonFile (
      configGen.makeThemeJsonConfig values {
        color_scheme = themeName;
      }
    );
  };
}
