{
  pkgs,
  config,
  ...
}:

let
  themeConfig = config.sysinit.theme;
in
{
  stylix = {
    enable = true;
    autoEnable = true;
    enableReleaseChecks = false;

    polarity = themeConfig.appearance;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${themeConfig.base16Scheme}.yaml";
    image = pkgs.fetchurl {
      url = "https://wallpapercave.com/wp/wp12329549.png";
      sha256 = "sha256-9R3cDgd1VslCF6mG6jBO64MEdRjCGzWE4m/dAjEixzk=";
    };

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
