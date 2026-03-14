{ pkgs, ... }:

let
  hyprlandWrapped = pkgs.writeShellScriptBin "hyprland-wrapped" ''
    set -euo pipefail

    export WLR_NO_HARDWARE_CURSORS=1
    export XDG_CURRENT_DESKTOP=Hyprland
    export XDG_SESSION_TYPE=wayland

    ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all || true

    exec ${pkgs.hyprland}/bin/Hyprland "$@"
  '';
in
{
  services.xserver.enable = false;
  services.dbus.enable = true;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    XDG_CURRENT_DESKTOP = "Hyprland";
  };

  environment.systemPackages = with pkgs; [
    hyprlandWrapped
    swww
    waybar
    rofi
    mako
    nemo
    pavucontrol
  ];
}
