{ pkgs, values, ... }:

let
  themeConfig = values.theme;

  base16Scheme =
    if themeConfig.colorscheme == "black-metal" then
      "black-metal"
    else if themeConfig.colorscheme == "rose-pine" && themeConfig.variant == "dawn" then
      "rose-pine-dawn"
    else if themeConfig.colorscheme == "rose-pine" then
      "rose-pine-moon"
    else if themeConfig.colorscheme == "gruvbox" then
      "gruvbox-dark-hard"
    else if themeConfig.colorscheme == "catppuccin" then
      "catppuccin-mocha"
    else
      "default-dark";
in
{
  stylix = {
    enable = true;
    autoEnable = true;

    polarity = themeConfig.appearance;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${base16Scheme}.yaml";

    fonts = {
      monospace.name = themeConfig.font.monospace;
      sansSerif.name = themeConfig.font.monospace;
      serif.name = themeConfig.font.monospace;
      sizes = {
        terminal = 11;
        applications = 11;
        desktop = 11;
        popups = 11;
      };
    };

    opacity = {
      terminal = themeConfig.transparency.opacity;
      applications = themeConfig.transparency.opacity;
      desktop = themeConfig.transparency.opacity;
      popups = themeConfig.transparency.opacity;
    };
  };
}
