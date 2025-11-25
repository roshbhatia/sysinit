# This is a template hardware configuration for arrakis
# Run 'nixos-generate-config --show-hardware-config' on the target machine
# and replace this file with the generated output

{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Boot configuration - update this based on your hardware
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ]; # Change to "kvm-amd" if using AMD CPU

  # Filesystems - REPLACE WITH YOUR ACTUAL CONFIGURATION
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  # Swap - configure if needed
  # swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

  # CPU configuration
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # OR for AMD:
  # hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # GPU configuration (for gaming)
  # Uncomment based on your GPU:

  # NVIDIA
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.nvidia.modesetting.enable = true;

  # AMD
  # services.xserver.videoDrivers = [ "amdgpu" ];

  # Intel
  # services.xserver.videoDrivers = [ "intel" ];
}
