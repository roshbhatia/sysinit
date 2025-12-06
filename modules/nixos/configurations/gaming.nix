{
  lib,
  pkgs,
  ...
}:

with lib;

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    goverlay
    heroic
    lutris
    mangohud
    protonup-qt
    vkBasalt
    vulkan-tools
  ];

  hardware.steam-hardware.enable = true;

  environment.sessionVariables = {
    # Force Electron apps (and some games) to use Wayland
    NIXOS_OZONE_WL = "1";
  };
}
