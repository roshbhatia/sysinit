{ lib, ... }:

{
  # Placeholder hardware configuration
  # This will be overridden by host-specific hardware.nix in /etc/nixos/hardware-configuration.nix
  # or defined in a host-specific module

  # For now, just a minimal config to avoid evaluation errors
  boot.loader.grub.enable = false;
  fileSystems."/" = lib.mkDefault {
    device = "/dev/null";
    fsType = "ext4";
  };
}
