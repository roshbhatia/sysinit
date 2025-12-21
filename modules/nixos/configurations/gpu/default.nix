_:

{
  hardware.graphics = {
    enable = true;
  };

  # Use open-source nouveau driver for better Wayland support
  services.xserver.videoDrivers = [ "nouveau" ];

  # Nouveau handles Wayland natively without special configuration
}
