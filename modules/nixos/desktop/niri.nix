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

  programs.xwayland.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config.common.default = "*";
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    XDG_CURRENT_DESKTOP = "niri";
    XCURSOR_THEME = "macOS";
    XCURSOR_SIZE = "16";
  };

  # ── 32-bit graphics (required for Steam/Wine) ──
  hardware.graphics.enable32Bit = true;

  # ── Gaming ──
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  programs.gamemode.enable = true;

  environment.systemPackages = [
    # Compositor
    niriPkg
    niriWrapped
    inputs.niri-flake.packages.${pkgs.system}.xwayland-satellite-unstable

    # Bar + launcher + notifications
    pkgs.waybar
    pkgs.rofi
    pkgs.mako

    # Wallpaper
    pkgs.swaybg

    # File management
    pkgs.nemo

    # Browser
    pkgs.firefox

    # Communication
    pkgs.vesktop

    # Music
    pkgs.cider

    # Media viewers
    pkgs.mpv
    pkgs.imv
    (pkgs.zathura.override { plugins = [ pkgs.zathuraPkgs.zathura_pdf_mupdf ]; })

    # Audio control
    pkgs.pavucontrol

    # Clipboard
    pkgs.wl-clipboard
    pkgs.cliphist

    # Authentication
    pkgs.polkit_gnome

    # Gaming
    pkgs.lutris
    pkgs.mangohud

    # Theming
    pkgs.papirus-icon-theme
    pkgs.apple-cursor
    pkgs.gruvbox-gtk-theme
  ];

  # Allow niri to run as a session
  security.polkit.enable = true;
}
