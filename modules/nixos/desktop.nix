# Desktop: display manager, Wayland, XDG portals, mangowc
{
  pkgs,
  lib,
  values,
  inputs,
  ...
}:

let
  themes = import ../shared/lib/theme { inherit lib; };
  semanticColors = themes.getSemanticColors values.theme.colorscheme values.theme.variant;

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

  mangoPackage = inputs.mangowc.packages.${pkgs.system}.default;

  mangoWrapper = pkgs.writeShellScriptBin "mango-wrapped" ''
    set -euo pipefail
    LOG_FILE="$HOME/.local/state/mango-debug.log"
    mkdir -p "$(dirname "$LOG_FILE")"
    {
      echo "=== Mangowc session started at $(date) ==="
      env | grep -E "(WAYLAND|XDG_SESSION|DISPLAY)" || true
    } >> "$LOG_FILE" 2>&1
    ${mangoPackage}/bin/mango "''${@}" >> "$LOG_FILE" 2>&1 || exit $?
  '';

  tuigreetTheme =
    "text=${colorToTuigreetTheme semanticColors.foreground.primary};"
    + "container=${colorToTuigreetTheme semanticColors.background.primary};"
    + "border=${colorToTuigreetTheme semanticColors.accent.primary};"
    + "title=${colorToTuigreetTheme semanticColors.accent.primary};"
    + "prompt=${colorToTuigreetTheme semanticColors.foreground.secondary};"
    + "input=${colorToTuigreetTheme semanticColors.accent.primary};"
    + "action=${colorToTuigreetTheme semanticColors.foreground.muted};"
    + "button=${colorToTuigreetTheme semanticColors.accent.secondary};"
    + "greet=${colorToTuigreetTheme semanticColors.foreground.primary}";
in
{
  # Disable X server, enable dbus
  services.xserver.enable = false;
  services.dbus.enable = true;

  # Mangowc compositor
  programs.mango.enable = true;

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    XDG_CURRENT_DESKTOP = "mango";
  };

  # Login manager (greetd + tuigreet)
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%R' --user-menu --remember --theme '${tuigreetTheme}' --cmd ${mangoWrapper}/bin/mango-wrapped";
      user = "greeter";
    };
  };

  # XDG portals for Wayland
  xdg.terminal-exec = {
    enable = true;
    package = pkgs.xdg-terminal-exec-mkhl;
    settings.default = [ "org.wezfurlong.wezterm.desktop" ];
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    wlr.enable = true;
    config.common.default = [
      "wlr"
      "gtk"
    ];
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
  };
}
