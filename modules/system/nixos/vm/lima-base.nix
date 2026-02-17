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

  # Boot configuration for Lima VM
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
  };

  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_scsi"
    "ahci"
    "sd_mod"
  ];
  boot.kernelModules = [ "virtiofs" ];

  # Filesystem - use virtio disk
  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };

  # Networking
  networking = {
    hostName = lib.mkDefault "lima-nixos";
    useDHCP = lib.mkDefault true;
    firewall.enable = lib.mkDefault false; # Lima networking is isolated
  };

  # SSH for Lima connection
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Cloud-init for Lima provisioning
  services.cloud-init = {
    enable = true;
    network.enable = true;
  };

  # Passwordless sudo for wheel group (dev user created by main config)
  security.sudo.wheelNeedsPassword = false;

  # Nix settings
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "dev"
    ];
    auto-optimise-store = true;
  };

  # Essential system packages
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
  ];

  # Enable zsh system-wide
  programs.zsh.enable = true;

  system.stateVersion = lib.mkDefault "25.05";
}
