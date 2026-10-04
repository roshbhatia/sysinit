{
  config,
  pkgs,
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
    inherit (themeConfig) enable;
    autoEnable = true;
    enableReleaseChecks = false;

    polarity = themeConfig.appearance;
    inherit base16Scheme;

    fonts = {
      monospace.name = themeConfig.font.monospace;
      sansSerif.name = themeConfig.font.monospace;
      serif.name = themeConfig.font.serif;
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
    pkgs.cm-web-fonts
    pkgs.source-serif
    pkgs.nerd-fonts.symbols-only
    pkgs.wumpusMono
    pkgs.ioskeleyMono
  ];
}
