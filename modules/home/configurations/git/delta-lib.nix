{ lib }:

with lib;

{
  getDeltaTheme =
    colorscheme: variant:
    let
      themeMap = {
        catppuccin = v: "catppuccin-${v}";
        "rose-pine" = v: "rose-pine-${v}";
        gruvbox = v: "gruvbox-${v}";
        solarized = v: "solarized-${v}";
        nord = v: "nord-${v}";
        everforest = v: "nord-${v}";
        kanagawa = v: "kanagawa-${v}";
        "black-metal" = v: "black-metal-${v}";
      };
    in
    if hasAttr colorscheme themeMap then
      themeMap.${colorscheme} variant
    else
      "${colorscheme}-${variant}";
}
