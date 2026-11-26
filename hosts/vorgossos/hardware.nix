{
  boot = {
    initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "usb_storage"
      "uas"
      "sd_mod"
      "nvme"
    ];
    kernel.sysctl = {
      "kernel.hung_task_timeout_secs" = 300;
      "kernel.hung_task_panic" = 1;
      "kernel.panic" = 10;
      "kernel.panic_on_oops" = 1;
    };
    kernelModules = [ "kvm-intel" ];
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/vorgossos-root";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-label/VORG-EFI";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };
  };
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  services.journald.settings.Journal = {
    Storage = "persistent";
    SystemMaxUse = "2G";
  };
  systemd.settings.Manager = {
    RuntimeWatchdogSec = "60s";
    RebootWatchdogSec = "10min";
  };
}
