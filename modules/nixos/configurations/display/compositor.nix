_:

{
  services = {
    xserver.enable = false;
    dbus.enable = true;
    # SDDM disabled - using greetd with tuigreet instead (see login.nix)
  };
}
