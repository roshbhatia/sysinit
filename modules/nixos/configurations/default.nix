{ lib, values, ... }:

{
  imports = [
    ./audio
    ./desktop
    ./hardware
    ./networking
    ./packages
    ./security
    ./stylix
    ./system
  ]
  ++ lib.optionals values.nix.gaming.enable [ ./gaming ];
}
