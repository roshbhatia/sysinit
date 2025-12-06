{
  lib,
  values,
  pkgs,
  ...
}:

with lib;

{
  # GPU configuration - only apply if GPU is enabled
  hardware.graphics = mkIf values.nixos.gpu.enable {
    enable = true;

    # AMD GPU packages
    extraPackages = mkIf (values.nixos.gpu.vendor == "amd") [
      pkgs.libva
      pkgs.vaapiVdpau
    ];

    # Generic GPU accelerated packages (32-bit)
    extraPackages32 = if pkgs.stdenv.isx86_64 then [ pkgs.driversi686Linux.libva ] else [ ];
  };

  # NVIDIA GPU specific configuration
  services.xserver.videoDrivers =
    mkIf (values.nixos.gpu.vendor == "nvidia" && values.nixos.gpu.enable)
      [
        "nvidia"
      ];

  hardware.nvidia = mkIf (values.nixos.gpu.vendor == "nvidia" && values.nixos.gpu.enable) {
    modesetting.enable = true;
    open = false; # Use proprietary driver
    nvidiaSettings = true;
  };
}
