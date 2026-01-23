{
  values,
  lib,
  ...
}:

let
  themes = import ../../../shared/lib/theme.nix { inherit lib; };
  themeNames = import ../../../shared/lib/theme/adapters/theme-names.nix { inherit lib; };
  themeName = themeNames.getWeztermTheme values.theme.colorscheme values.theme.variant;
in
{
  # Disable stylix for wezterm - using custom theme integration from shared/lib/theme.nix
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
