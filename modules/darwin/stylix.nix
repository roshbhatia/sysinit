{
  pkgs,
  config,
  ...
}:

let
  themeConfig = config.sysinit.theme;
  base16Scheme =
    if builtins.isString themeConfig.base16Scheme then
      "${pkgs.base16-schemes}/share/themes/${themeConfig.base16Scheme}.yaml"
    else
      themeConfig.base16Scheme;
in
{
  stylix = {
    # The owner's choice, not a constant. Everything that reads a color reads it
    # through `modules/shared/theme-colors.nix`, which answers with a fallback
    # when this is off, so nothing downstream has to know.
    enable = themeConfig.enable;
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
