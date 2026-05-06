{
  pkgs,
  config,
  ...
}:

let
  themeConfig = config.sysinit.theme;
  # String → resolve to a yaml in pkgs.base16-schemes; attrset → pass directly
  # to stylix's mkSchemeAttrs.
  base16Scheme =
    if builtins.isString themeConfig.base16Scheme then
      "${pkgs.base16-schemes}/share/themes/${themeConfig.base16Scheme}.yaml"
    else
      themeConfig.base16Scheme;
in
{
  stylix = {
    enable = true;
    autoEnable = true;
    enableReleaseChecks = false;

    polarity = themeConfig.appearance;
    inherit base16Scheme;
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

  fonts.packages = [
    pkgs.nerd-fonts.symbols-only
    pkgs.wumpusMono
    pkgs.ioskeleyMono
    pkgs.ibm-plex
    pkgs.bookerly
  ];
}
