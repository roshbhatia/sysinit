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

  # Use host's /nix/store as an additional binary cache
  # The /nix-host mount is configured in lima.yaml
  nix.settings = {
    extra-substituters = [
      "file:///nix-host/store"
      "https://nix-community.cachix.org"
      "https://cache.iog.io"
      "https://numtide.cachix.org"
      "https://devenv.cachix.org"
    ];
    trusted-substituters = [
      "file:///nix-host/store"
      "https://nix-community.cachix.org"
      "https://cache.iog.io"
      "https://numtide.cachix.org"
      "https://devenv.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };

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
