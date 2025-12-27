_:

{
  services = {
    xserver.enable = false;
    dbus.enable = true;
    displayManager.sddm = {
      wayland.enable = true;
      enable = true;
    };
  };
}
