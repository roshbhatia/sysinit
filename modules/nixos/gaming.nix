# Gaming: Steam, Gamemode, gaming packages (conditionally imported)
{ pkgs, ... }:

{
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    protontricks.enable = true;
    extest.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  programs.gamemode.enable = true;
  hardware.steam-hardware.enable = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    mangohud
    protonup-qt
    lutris
    vulkan-validation-layers
  ];
}
