{
  lib,
  values,
  pkgs,
  ...
}:

with lib;

{
  # X11 Display Server configuration
  services.xserver = mkIf (values.nixos.desktop.displayServer == "x11") {
    enable = true;
    xkb.layout = "us";

    # GNOME Desktop Environment (X11)
    desktopManager.gnome = mkIf (values.nixos.desktop.desktopEnvironment == "gnome") {
      enable = true;
    };

    # KDE Plasma Desktop Environment (X11) - disabled for now
    # desktopManager.plasmaX11 = mkIf (values.nixos.desktop.desktopEnvironment == "kde") {
    #   enable = true;
    # };
  };

  # Wayland configuration (Sway)
  programs.sway = mkIf (values.nixos.desktop.displayServer == "wayland") {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  # SDDM login manager for all DMs
  services.displayManager.sddm = mkIf (values.nixos.desktop.displayServer == "wayland") {
    enable = true;
    wayland.enable = true;
  };

  # Exclude packages to reduce closure size (GNOME)
  environment.gnome.excludePackages = mkIf (values.nixos.desktop.desktopEnvironment == "gnome") [
    pkgs.epiphany
    pkgs.gedit
    pkgs.gnome-calendar
    pkgs.gnome-music
    pkgs.totem
    pkgs.orca
  ];
}
