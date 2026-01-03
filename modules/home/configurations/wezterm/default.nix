{
  values,
  lib,
  ...
}:

let
  themeNames = import ../../../shared/lib/theme/adapters/theme-names.nix { inherit lib; };
  themeName = themeNames.getWeztermTheme values.theme.colorscheme values.theme.variant;
  configGen = import ../../../shared/lib/config-gen.nix { inherit lib; };

  kansoThemeFiles = {
    wave = ./colors/kanso-ink.lua;
    dragon = ./colors/kanso-mist.lua;
  };
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
  }
  // (
    if values.theme.colorscheme == "kanagawa" then
      {
        "wezterm/colors/${kansoThemeFiles.${values.theme.variant} or "kanso-ink.lua"}".source =
          kansoThemeFiles.${values.theme.variant} or ./colors/kanso-ink.lua;
      }
    else
      { }
  );
}
