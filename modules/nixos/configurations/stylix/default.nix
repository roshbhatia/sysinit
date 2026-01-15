{
  pkgs,
  values,
  ...
}:

let
  themeConfig = values.theme;
  polarityValue = themeConfig.appearance;
  monospaceFontName = themeConfig.font.monospace;
  base16Scheme = "catppuccin-mocha";
in
{
  stylix = {
    enable = true;
    autoEnable = true;
    enableReleaseChecks = false;

    polarity = polarityValue;
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

    opacity = {
      terminal = themeConfig.transparency.opacity;
      applications = themeConfig.transparency.opacity;
      desktop = 1.0;
      popups = themeConfig.transparency.opacity;
    };

    targets = {
      gtk.enable = true;
      hyprland.enable = false; # Using custom theming
    };
  };
}
