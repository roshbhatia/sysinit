# SwayFX compositor + desktop packages
{ pkgs, ... }:

let
  swayWrapped = pkgs.writeShellScriptBin "sway-wrapped" ''
    set -euo pipefail

    export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"
    export WLR_NO_HARDWARE_CURSORS=1
    export WLR_RENDERER=vulkan
    export XDG_CURRENT_DESKTOP=sway
    export XDG_SESSION_TYPE=wayland
    export NIXOS_OZONE_WL=1
    export GDK_BACKEND=wayland
    export QT_QPA_PLATFORM=wayland
    export MOZ_ENABLE_WAYLAND=1

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
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = "*";
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER = "vulkan";
    XDG_CURRENT_DESKTOP = "sway";
    XCURSOR_THEME = "macOS";
    XCURSOR_SIZE = "16";
  };

  # 32-bit graphics (required for Steam/Wine)
  hardware.graphics.enable32Bit = true;

  # Gaming
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    swayWrapped
    swaybg
    grim
    slurp
    wl-clipboard
    cliphist

    # Bar
    i3status-rust

    # Launcher + notifications
    rofi
    mako

    # File management
    nemo

    # Browser (configured via home-manager firefox module)

    # Communication
    vesktop

    # Music
    cider

    # Media viewers
    mpv
    imv
    (zathura.override { plugins = [ zathuraPkgs.zathura_pdf_mupdf ]; })

    # Audio control
    pavucontrol

    # Authentication
    polkit_gnome

    # Gaming
    lutris
    mangohud

    # Theming
    papirus-icon-theme
    apple-cursor
    gruvbox-gtk-theme
  ];

  security.polkit.enable = true;

  # 1Password
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "rshnbhatia" ];
  };

}
