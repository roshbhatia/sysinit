{ lib, values, ... }:

{
  imports = [
    ./boot
    ./display
    ./firewall
    ./gpu
    ./audio
    ./hostname
    ./security
    ./tailscale
    ./networking
    ./virtualisation
    ./xdg
    ./services
    ./system
    ./compat
    ./stylix
    ./hardware
    ./user
  ]
  ++ lib.optionals values.nix.gaming.enable [ ./gaming ];
}
