# NixOS configuration entry point
{ ... }:

{
  imports = [
    ./configurations
    ./home-manager.nix
  ];
}
