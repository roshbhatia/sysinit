{
  pkgs,
  values,
  customUtils,
  ...
}:

let
  inherit (customUtils.theme) fontNames;

  base16SchemeMap = {
    "catppuccin-latte" = "catppuccin-latte";
    "catppuccin-frappe" = "catppuccin-frappe";
    "catppuccin-macchiato" = "catppuccin-macchiato";
    "catppuccin-mocha" = "catppuccin-mocha";
    "rose-pine-main" = "rose-pine";
    "rose-pine-moon" = "rose-pine-moon";
    "rose-pine-dawn" = "rose-pine-dawn";
    "gruvbox-dark" = "gruvbox-dark-medium";
    "gruvbox-light" = "gruvbox-light-medium";
    "nord-dark" = "nord";
    "solarized-dark" = "solarized-dark";
    "solarized-light" = "solarized-light";
    "kanagawa-wave" = "kanagawa";
    "kanagawa-dragon" = "kanagawa";
    "kanagawa-lotus" = "kanagawa";
    "everforest-dark" = "everforest";
    "everforest-light" = "everforest";
    "black-metal-dark" = "black-metal";
  };

  themeKey = "${values.theme.colorscheme}-${values.theme.variant}";
  base16Scheme = base16SchemeMap.${themeKey} or "catppuccin-macchiato";
  polarity = values.theme.appearance;

  monospaceFontName = values.theme.font.monospace;
  monospaceFontPackage = fontNames.getFontPackage pkgs monospaceFontName;
in
{
  stylix.enable = true;
  stylix.autoEnable = true;
  stylix.polarity = polarity;

  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/${base16Scheme}.yaml";

  stylix.fonts = {
    monospace = {
      name = monospaceFontName;
      package = monospaceFontPackage;
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
