{ lib, values, ... }:

{
  imports = [
    ./audio.nix
    ./desktop.nix
    ./hardware.nix
    ./networking.nix
    ./packages.nix
    ./security.nix
    ./stylix.nix
    ./system.nix
  ]
  ++ lib.optionals values.nix.gaming.enable [ ./gaming.nix ];
}
