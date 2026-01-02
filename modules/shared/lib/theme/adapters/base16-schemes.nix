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

    # Gruvbox - all variants (format: {colorscheme}-{variant})
    "gruvbox-dark-hard" = "gruvbox-dark-hard";
    "gruvbox-dark-medium" = "gruvbox-dark-medium";
    "gruvbox-dark-soft" = "gruvbox-dark-soft";
    "gruvbox-dark" = "gruvbox-dark-medium";
    "gruvbox-light-hard" = "gruvbox-light-hard";
    "gruvbox-light-medium" = "gruvbox-light-medium";
    "gruvbox-light-soft" = "gruvbox-light-soft";
    "gruvbox-light" = "gruvbox-light-medium";
    # Support legacy variant names (just colorscheme name)
    "gruvbox" = "gruvbox-dark-medium";

    "nord-default" = "nord";
    "nord-light" = "nord";
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
