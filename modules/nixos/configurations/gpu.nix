{
  pkgs,
  ...
}:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      libva
    ];
    extraPackages32 = with pkgs.driversi686Linux; [
      libva
    ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true; # Required for Wayland support
    open = false; # Nvidia GPUs use a proprietary driver
    nvidiaSettings = true; # Enable nvidia-settings utility
  };
}
