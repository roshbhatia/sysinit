_:

{
  hardware.graphics = {
    enable = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    enabled = true;
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false;
  };
}
