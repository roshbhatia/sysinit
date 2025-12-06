{ lib, ... }:

{
  boot.loader.grub.enable = false;
  fileSystems."/" = lib.mkDefault {
    device = "/dev/null";
    fsType = "ext4";
  };
}
