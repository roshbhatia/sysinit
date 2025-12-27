{
  values,
  lib,
  ...
}:

let
  themeNames = import ../../../shared/lib/theme/adapters/theme-names.nix { inherit lib; };
  themeName = themeNames.getWeztermTheme values.theme.colorscheme values.theme.variant;
in
{
  stylix.targets.wezterm.enable = false;

  xdg.configFile = {
    "wezterm/wezterm.lua".source = ./wezterm.lua;
    "wezterm/lua".source = ./lua;
    "wezterm/config.json".text = builtins.toJSON {
      font = {
        inherit (values.theme.font) monospace symbols;
      };
      color_scheme = themeName;
      transparency = {
        inherit (values.theme.transparency) opacity blur;
      };
    };
  };
}
