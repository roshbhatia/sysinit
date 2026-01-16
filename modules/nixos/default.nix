# NixOS configuration entry point
{ lib, values, ... }:

{
  imports = [
    ./system.nix
    ./hardware.nix
    ./desktop.nix
    ./networking.nix
    ./audio.nix
    ./security.nix
    ./packages.nix
    ./stylix.nix
    ./home-manager.nix
  ]
  ++ lib.optionals values.nix.gaming.enable [ ./gaming.nix ];
}
