{
  config,
  pkgs,
  ...
}:

let
  themeConfig = config.sysinit.theme;
in
{
  stylix = {
    enable = true;
    autoEnable = true;

    polarity = themeConfig.appearance;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${themeConfig.base16Scheme}.yaml";

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
    pkgs.nerd-fonts.departure-mono
  ];
}
