# Nostromo - Personal NixOS Lima VM
{ ... }:

{
  imports = [
    ./base/lima.nix
  ];

  # Host-specific networking
  networking.hostName = "nostromo";

  # Add any nostromo-specific configuration here
}
