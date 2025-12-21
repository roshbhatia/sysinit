{
  pkgs,
  ...
}:

{
  programs.sway = {
    enable = true;
    package = pkgs.sway;
    xwayland.enable = true;
  };

  services.xserver.enable = false;

  services.dbus.enable = true;
  xdg.portal.enable = true;
  xdg.portal.wlr.enable = true;
}
