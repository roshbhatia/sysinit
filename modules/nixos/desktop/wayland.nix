{ pkgs, ... }:

let
  swayWrapped = pkgs.writeShellScriptBin "sway-wrapped" ''
    set -euo pipefail

    export WLR_NO_HARDWARE_CURSORS=1
    export WLR_RENDERER=vulkan
    export XDG_CURRENT_DESKTOP=sway
    export XDG_SESSION_TYPE=wayland

    ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all || true

    exec ${pkgs.sway}/bin/sway --unsupported-gpu "$@"
  '';
in
{
  services.xserver.enable = false;
  services.dbus.enable = true;

  programs.sway = {
    enable = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER = "vulkan";
    XDG_CURRENT_DESKTOP = "sway";
  };

  environment.systemPackages = with pkgs; [
    swayWrapped
    waybar
    rofi
    mako
    nemo
    pavucontrol
  ];
}
