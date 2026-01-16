# Hardware configuration: kernel modules, filesystems, GPU
{ config, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Kernel modules
  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
  };

  # Filesystems (arrakis-specific UUIDs)
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/6ef554bd-f602-4f13-a2ba-9d540397ebc3";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/5495-7D54";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
  };

  # Graphics
  hardware.graphics.enable = true;

  # NVIDIA GPU
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}
