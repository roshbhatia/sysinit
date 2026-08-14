{
  config,
  pkgs,
  lib,
  ...
}:

let
  themeLib = import ../../shared/theme-colors.nix { inherit lib; };
  themeColors = themeLib.colorsOf config;
  colorToTuigreetTheme =
    color:
    let
      colorMap = {
        "000000" = "black";
        "ffffff" = "white";
        "ff0000" = "red";
        "00ff00" = "green";
        "0000ff" = "blue";
        "ffff00" = "yellow";
        "ff00ff" = "magenta";
        "00ffff" = "cyan";
      };
      cleanHex = lib.toLower (lib.removePrefix "#" color);
    in
    colorMap.${cleanHex} or cleanHex;

  tuigreetTheme =
    "text=${colorToTuigreetTheme "#${themeColors.base05}"};"
    + "container=${colorToTuigreetTheme "#${themeColors.base00}"};"
    + "border=${colorToTuigreetTheme "#${themeColors.base0D}"};"
    + "title=${colorToTuigreetTheme "#${themeColors.base0D}"};"
    + "prompt=${colorToTuigreetTheme "#${themeColors.base04}"};"
    + "input=${colorToTuigreetTheme "#${themeColors.base0D}"};"
    + "action=${colorToTuigreetTheme "#${themeColors.base03}"};"
    + "button=${colorToTuigreetTheme "#${themeColors.base0C}"};"
    + "greet=${colorToTuigreetTheme "#${themeColors.base05}"}";
in
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%R' --user-menu --remember --theme '${tuigreetTheme}' --cmd sway-wrapped";
        user = "greeter";
      };
      initial_session = {
        command = "sway-wrapped";
        user = config.sysinit.user.username;
      };
    };
  };

  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "systemd.show_status=auto"
    "rd.udev.log_level=3"
  ];

  security.pam.services.greetd.enableGnomeKeyring = true;
}
