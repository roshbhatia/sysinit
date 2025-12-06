{ ... }:

{
  imports = [
    ./boot.nix
    ./display.nix
    ./gpu.nix
    ./audio.nix
    # ./hardware.nix is included separately by the NixOS build system
  ];
}
