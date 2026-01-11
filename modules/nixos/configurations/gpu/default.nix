{
  config,
  ...
}:
{
  hardware.graphics = {
    enable = true;
    enable32bit = true;
  };

  hardware.opengl = {
    enable = true;
    driSupport = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}
