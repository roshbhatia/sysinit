{ config, ... }:

{
  imports = [
    ./boot.nix
    ./display.nix
    ./gpu.nix
    ./audio.nix
    ./gaming.nix
    ./shell.nix
  ];

  # Only enable gaming on desktop (arrakis), not on server
  programs.steam.enable = config.networking.hostName == "arrakis";
  programs.gamemode.enable = config.networking.hostName == "arrakis";
  hardware.steam-hardware.enable = config.networking.hostName == "arrakis";
}
