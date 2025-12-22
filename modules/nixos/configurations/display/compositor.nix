_:

{
  services.xserver.enable = false;
  services.dbus.enable = true;
  services.displayManager.sddm = {
    wayland.enable = true;
    enable = true;
  };
}
