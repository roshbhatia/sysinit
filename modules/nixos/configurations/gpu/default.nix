{
  config,
  ...
}:
{
  hardware.graphics = {
    enable = true;
  };

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32bit = true;
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
