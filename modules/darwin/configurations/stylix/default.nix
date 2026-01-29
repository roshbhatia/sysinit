# Darwin stylix: theming
{ pkgs, values, ... }:

let
  themeConfig = values.theme;
  base16Scheme =
    if themeConfig.colorscheme == "black-metal" then
      "black-metal"
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
    enableReleaseChecks = false;

    polarity = themeConfig.appearance;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${base16Scheme}.yaml";

    fonts = {
      monospace.name = themeConfig.font.monospace;
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

    opacity = {
      terminal = themeConfig.transparency.opacity;
      applications = themeConfig.transparency.opacity;
      desktop = 1.0;
      popups = themeConfig.transparency.opacity;
    };

    targets.jankyborders.enable = true;
  };
}
