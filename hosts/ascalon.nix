# Ascalon - Persistent NixOS VM
# Full NixOS system running in Lima
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

  # Enable Lima integration
  services.lima.enable = true;

  # Nix configuration
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "@wheel" ];
  };

  # Hostname
  networking.hostName = "ascalon";

  # SSH
  services.openssh.enable = true;

  # Sudo without password
  security.sudo.wheelNeedsPassword = false;

  # Boot configuration for Lima/QEMU
  boot = {
    kernelParams = [ "console=tty0" ];
    kernelPackages = pkgs.linuxPackages_latest;
    loader.grub = {
      device = "nodev";
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

  # Filesystems
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

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  # Home-manager
  home-manager.users.dev = {
    imports = [
      # Ascalon gets language runtimes (same as macOS)
      ../modules/home/packages/language-runtimes.nix
    ];

    programs.home-manager.enable = true;
  };

  system.stateVersion = lib.mkForce "25.11";
}
