_:

{
  hardware.graphics = {
    enable = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false;
    # Required for Wayland/Sway support
    forceFullCompositionPipeline = true;
  };

  # Enable KMS for NVIDIA (required for Wayland)
  boot.kernelParams = [ "nvidia_drm.modeset=1" ];
}
