{ pkgs, ... }:

{
  # Disable X server, enable dbus
  services.xserver.enable = false;
  services.dbus.enable = true;

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    XDG_CURRENT_DESKTOP = "mango";
  };

  # XDG portals for Wayland
  xdg.terminal-exec = {
    enable = true;
    package = pkgs.xdg-terminal-exec;
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

  # Extra desktop packages
  environment.systemPackages = with pkgs; [
    swww # Wallpaper daemon
    waybar # Status bar
    fuzzel # App launcher
    mako # Notification daemon
    nemo # File manager
    pavucontrol # Audio control
  ];
}
