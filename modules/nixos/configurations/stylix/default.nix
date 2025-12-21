{
  pkgs,
  values,
  lib,
  ...
}:

let
  themeLib = import ../../shared/lib/theme { inherit lib; };
  themeKey = "${values.theme.colorscheme}-${values.theme.variant}";
  base16Scheme = themeLib.base16Schemes.getBase16Scheme themeKey;
  polarity = values.theme.appearance;
  monospaceFontName = values.theme.font.monospace;
in
{
  stylix.enable = true;
  stylix.autoEnable = true;
  stylix.polarity = polarity;

  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/${base16Scheme}.yaml";

  stylix.fonts = {
    monospace = {
      name = monospaceFontName;
    };
    sansSerif = {
      name = "DejaVu Sans";
      package = pkgs.dejavu_fonts;
    };
    serif = {
      name = "DejaVu Serif";
      package = pkgs.dejavu_fonts;
    };
    sizes = {
      terminal = 11;
      applications = 11;
      desktop = 11;
      popups = 11;
    };
  };

  stylix.targets = {
    gtk.enable = true;
  };
}
