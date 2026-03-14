{ pkgs, inputs, ... }:

let
  niriPkg = inputs.niri-flake.packages.${pkgs.system}.niri-unstable;

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

    exec ${niriPkg}/bin/niri "$@"
  '';
in
{
  services.xserver.enable = false;
  services.dbus.enable = true;

  # Enable xwayland via the niri-flake's xwayland-satellite
  programs.xwayland.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config.common.default = "*";
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    XDG_CURRENT_DESKTOP = "niri";
  };

  environment.systemPackages = [
    niriPkg
    niriWrapped
    inputs.niri-flake.packages.${pkgs.system}.xwayland-satellite-unstable
    pkgs.rofi
    pkgs.mako
    pkgs.nemo
    pkgs.pavucontrol
    pkgs.wl-clipboard
    pkgs.swaylock
    pkgs.swaybg
    pkgs.firefox
    pkgs.papirus-icon-theme
  ];

  # Icon theme for rofi and GTK apps
  environment.sessionVariables.XCURSOR_THEME = "Adwaita";

  # Allow niri to run as a session
  security.polkit.enable = true;
}
