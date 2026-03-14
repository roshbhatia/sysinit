{ pkgs, inputs, ... }:

let
  niriWrapped = pkgs.writeShellScriptBin "niri-wrapped" ''
    set -euo pipefail

    export WLR_NO_HARDWARE_CURSORS=1
    export XDG_CURRENT_DESKTOP=niri
    export XDG_SESSION_TYPE=wayland
    export NIXOS_OZONE_WL=1
    export GDK_BACKEND=wayland
    export QT_QPA_PLATFORM=wayland
    export MOZ_ENABLE_WAYLAND=1

    ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all || true

    exec ${pkgs.niri}/bin/niri "$@"
  '';
in
{
  imports = [
    inputs.niri-flake.nixosModules.niri
  ];

  programs.niri = {
    enable = true;
  };

  services.xserver.enable = false;
  services.dbus.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    XDG_CURRENT_DESKTOP = "niri";
  };

  environment.systemPackages = with pkgs; [
    niriWrapped
    rofi
    mako
    nemo
    pavucontrol
    wl-clipboard
    swaylock
    latest.firefox-bin
  ];
}
