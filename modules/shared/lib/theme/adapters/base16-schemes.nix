_:

let
  schemeMap = {
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
in
{
  inherit schemeMap;
  getBase16Scheme = themeKey: schemeMap.${themeKey} or "catppuccin-macchiato";
}
