# Hardware configuration for arrakis (physical x86_64 desktop)
{ config, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Bootloader for physical UEFI system
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

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

  # Hostname
  networking.hostName = "arrakis";

  # Sunshine KMS capture needs CAP_SYS_ADMIN (capSysAdmin=true in sway.nix),
  # which triggers AT_SECURE and blocks LD_LIBRARY_PATH. Patch /run/opengl-driver/lib
  # into the RPATH so libnvidia-encode and libcuda are found at runtime.
  nixpkgs.overlays = [
    (final: prev: {
      sunshine = prev.sunshine.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.patchelf ];
        postFixup =
          (old.postFixup or "")
          + ''
            patchelf --add-rpath /run/opengl-driver/lib $out/bin/sunshine
          '';
      });
    })
  ];
}
