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
    enable = true;
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
