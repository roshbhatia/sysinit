_:

{
  programs.sway = {
    enable = true;
    xwayland.enable = true;
  };

  services.xserver.enable = false;

  services.dbus.enable = true;
}
