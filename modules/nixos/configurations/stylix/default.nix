{
  pkgs,
  values,
  lib,
  ...
}:

let
  themeLib = import ../../../shared/lib/theme { inherit lib; };
  themeKey = "${values.theme.colorscheme}-${values.theme.variant}";
  base16Scheme = themeLib.base16Schemes.getBase16Scheme themeKey;
  polarity = values.theme.appearance;
  monospaceFontName = values.theme.font.monospace;
in
{
  stylix = {
    enable = true;
    autoEnable = true;
    inherit polarity;

    base16Scheme = "${pkgs.base16-schemes}/share/themes/${base16Scheme}.yaml";

    fonts = {
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

    targets = {
      gtk.enable = true;
    };
  };
}
