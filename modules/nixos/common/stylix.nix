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
    # The owner's choice, not a constant. Everything that reads a color reads it
    # through `modules/shared/theme-colors.nix`, which answers with a fallback
    # when this is off, so nothing downstream has to know.
    enable = themeConfig.enable;
    autoEnable = true;

    polarity = themeConfig.appearance;
    inherit base16Scheme;

    image = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";

    fonts = {
      monospace = {
        name = themeConfig.font.monospace;
      };
      sansSerif = {
        name = themeConfig.font.monospace;
      };
      serif = {
        name = themeConfig.font.monospace;
      };
    };
  };

  fonts.packages = [
    pkgs.nerd-fonts.symbols-only
    pkgs.wumpusMono
    pkgs.ioskeleyMono
  ];
}
