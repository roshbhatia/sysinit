_:

let
  schemeMap = {
    "black-metal-dark" = "black-metal";
    "catppuccin-frappe" = "catppuccin-frappe";
    "catppuccin-latte" = "catppuccin-latte";
    "catppuccin-macchiato" = "catppuccin-macchiato";
    "catppuccin-mocha" = "catppuccin-mocha";
    "everforest-dark" = "everforest";
    "everforest-light" = "everforest";
    "gruvbox-dark" = "gruvbox-dark-hard";
    "gruvbox-light" = "gruvbox-light-hard";
    "kanagawa-dragon" = "kanagawa";
    "kanagawa-lotus" = "kanagawa";
    "kanagawa-wave" = "kanagawa";
    "kanso-ink" = "kanagawa";
    "kanso-mist" = "kanagawa";
    "kanso-pearl" = "kanagawa";
    "kanso-zen" = "kanagawa";
    "nord-default" = "nord";
    "nord-light" = "nord";
    "rose-pine-dawn" = "rose-pine-dawn";
    "rose-pine-main" = "rose-pine";
    "rose-pine-moon" = "rose-pine-moon";
    "solarized-dark" = "solarized-dark";
    "solarized-light" = "solarized-light";
    "tokyonight-day" = "tokyo-night-light";
    "tokyonight-night" = "tokyo-night-dark";
    "tokyonight-storm" = "tokyo-night-storm";
  };
in
{
  inherit schemeMap;
  getBase16Scheme = themeKey: schemeMap.${themeKey} or "catppuccin-macchiato";
}
