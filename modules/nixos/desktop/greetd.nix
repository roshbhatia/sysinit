{ config, pkgs, lib, ... }:

let
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

  # Use stylix base16 colors directly
  tuigreetTheme =
    "text=${colorToTuigreetTheme "#${config.lib.stylix.colors.base05}"};"
    + "container=${colorToTuigreetTheme "#${config.lib.stylix.colors.base00}"};"
    + "border=${colorToTuigreetTheme "#${config.lib.stylix.colors.base0D}"};"
    + "title=${colorToTuigreetTheme "#${config.lib.stylix.colors.base0D}"};"
    + "prompt=${colorToTuigreetTheme "#${config.lib.stylix.colors.base04}"};"
    + "input=${colorToTuigreetTheme "#${config.lib.stylix.colors.base0D}"};"
    + "action=${colorToTuigreetTheme "#${config.lib.stylix.colors.base03}"};"
    + "button=${colorToTuigreetTheme "#${config.lib.stylix.colors.base0C}"};"
    + "greet=${colorToTuigreetTheme "#${config.lib.stylix.colors.base05}"}";
in
{
  # Login manager (greetd + tuigreet)
  services.greetd = {
    enable = true;
    settings.default_session = {
      # Use mangowc as the default session
      command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%R' --user-menu --remember --theme '${tuigreetTheme}' --cmd mango";
      user = "greeter";
    };
  };

  # Unlock Greetd keyring on login
  security.pam.services.greetd.enableGnomeKeyring = true;
}
