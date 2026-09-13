{
  config,
  pkgs,
  ...
}:

# The theme core both platforms share. Each platform module imports this and
# adds only what is genuinely platform-specific: the wallpaper, and the font
# packages that platform ships. Keeping two full copies let the NixOS one drift
# and lose opacity, font sizes, and two font packages.

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
  ];
}
