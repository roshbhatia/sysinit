{ lib, ... }:
{
  # Use systemd-boot bootloader
  boot.loader.systemd-boot = {
    enable = lib.mkDefault true;
    configurationLimit = lib.mkDefault 10;
  };

  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  # Enable kernel modules
  boot.kernelModules = lib.mkDefault [ "kvm-intel" "kvm-amd" ];

  # Clean /tmp on boot
  boot.tmp.cleanOnBoot = lib.mkDefault true;
}
