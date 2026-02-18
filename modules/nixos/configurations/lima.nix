# Lima VM configuration - imported when isLima = true
# Requires nixos-lima.nixosModules.lima to be included (done in lib/builders.nix)
{
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Enable Lima guest services (lima-init, lima-guestagent)
  services.lima.enable = true;

  # Boot configuration for Lima/QEMU (overrides systemd-boot from system.nix)
  boot = {
    kernelParams = [ "console=tty0" ];
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = lib.mkForce false;
      grub = {
        enable = lib.mkForce true;
        device = "nodev";
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
    };
  };

  # Filesystems for Lima QEMU disk layout
  fileSystems."/boot" = {
    device = "/dev/vda1";
    fsType = "vfat";
  };
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
    options = [
      "noatime"
      "nodiratime"
      "discard"
    ];
  };

  # Lima state version (matches nixos-lima image)
  system.stateVersion = lib.mkForce "25.11";
}
