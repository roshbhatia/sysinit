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

    # Gruvbox - variants map to base16 schemes
    "gruvbox-dark" = "gruvbox-dark-hard";
    "gruvbox-light" = "gruvbox-light-hard";

    "nord-default" = "nord";
    "nord-light" = "nord";
    "solarized-dark" = "solarized-dark";
    "solarized-light" = "solarized-light";
    "kanagawa-lotus" = "kanagawa";
    "kanagawa-wave" = "kanagawa";
    "kanagawa-dragon" = "kanagawa";
    "kanso-zen" = "kanagawa";
    "kanso-ink" = "kanagawa";
    "kanso-mist" = "kanagawa";
    "kanso-pearl" = "kanagawa";
    "everforest-dark" = "everforest";
    "everforest-light" = "everforest";
    "black-metal-dark" = "black-metal";
    "tokyonight-night" = "tokyo-night-dark";
    "tokyonight-storm" = "tokyo-night-storm";
    "tokyonight-day" = "tokyo-night-light";
  };
in
{
  inherit schemeMap;
  getBase16Scheme = themeKey: schemeMap.${themeKey} or "catppuccin-macchiato";
}
