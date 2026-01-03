{ lib }:

with lib;

let
  colorschemes = {
    catppuccin = {
      latte = "Catppuccin Latte";
      macchiato = "Catppuccin Macchiato";
    };
    "rose-pine" = {
      dawn = "Rosé Pine Dawn";
      moon = "Rosé Pine Moon";
    };
    gruvbox = {
      dark = "Gruvbox dark";
      light = "Gruvbox light";
    };
    solarized = {
      dark = "Solarized Dark";
      light = "Solarized Light";
    };
    nord = {
      dark = "Nord";
    };
    everforest = {
      dark-hard = "Everforest Dark Hard";
      dark-medium = "Everforest Dark";
      dark-soft = "Everforest Dark Soft";
      light-hard = "Everforest Light Hard";
      light-medium = "Everforest Light";
      light-soft = "Everforest Light Soft";
    };
    kanagawa = {
      wave = "kanso_ink";
      dragon = "kanso_mist";
    };
    "black-metal" = {
      gorgoroth = "Black Metal";
    };
  };

  getThemeName =
    colorscheme: variant:
    let
      schemeMap = colorschemes.${colorscheme} or { };
      themeName = schemeMap.${variant} or "${colorscheme}-${variant}";
    in
    themeName;
in

{
  inherit getThemeName;
}
