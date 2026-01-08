{
  values,
  lib,
  ...
}:

let
  themes = import ../../../shared/lib/theme { inherit lib; };
  themeNames = import ../../../shared/lib/theme/adapters/theme-names.nix { inherit lib; };
  themeName = themeNames.getWeztermTheme values.theme.colorscheme values.theme.variant;
in
{
  stylix.targets.wezterm.enable = false;

  xdg.configFile = {
    "wezterm/wezterm.lua".source = ./wezterm.lua;
    "wezterm/lua".source = ./lua;
    "wezterm/config.json".text = themes.toJsonFile (
      themes.makeThemeJsonConfig values {
        color_scheme = themeName;
      }
    );
    "wezterm/colors/kanso-ink.lua".source = ./colors/kanso-ink.lua;
    "wezterm/colors/kanso-mist.lua".source = ./colors/kanso-mist.lua;
  };
}
