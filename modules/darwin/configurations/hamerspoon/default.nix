{
  config,
  pkgs,
  lib,
  values,
  ...
}:
let
  themes = import ../../../../lib/theme { inherit lib; };
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  semanticColors = themes.utils.createSemanticMapping palette;
  backgroundColor = semanticColors.background.primary;
  highlightColor = semanticColors.accent.primary;
  hexToRgba =
    hex: alpha:
    let
      r = builtins.fromJSON "[" + builtins.substring 1 2 hex + ",0]";
      g = builtins.fromJSON "[" + builtins.substring 3 2 hex + ",0]";
      b = builtins.fromJSON "[" + builtins.substring 5 2 hex + ",0]";
      toFloat = n: (builtins.div (builtins.elemAt n 0) 255.0);
    in
    "{"
    + toString (toFloat r)
    + ","
    + toString (toFloat g)
    + ","
    + toString (toFloat b)
    + ","
    + alpha
    + "}";
  backgroundRgba = hexToRgba (lib.removePrefix "#" backgroundColor) "0.85";
  highlightRgba = hexToRgba (lib.removePrefix "#" highlightColor) "0.85";
  themeLua = pkgs.writeText "theme.lua" ''
    return {
      backgroundColor = ${backgroundRgba},
      highlightColor = ${highlightRgba},
      showThumbnails = false,
      showSelectedTitle = false,
    }
  '';
in
{
  config = {
    home.file.".hammerspoon/init.lua".source = ./init.lua;
    home.file.".hammerspoon/lua/app_switcher.lua".source = ./lua/app_switcher.lua;
    home.file.".hammerspoon/theme.lua".source = themeLua;
  };
}
