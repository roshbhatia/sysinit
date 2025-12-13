{
  config,
  lib,
  pkgs,
  ...
}:

let
  isDesktop = config.networking.hostName == "arrakis";
in
{
  programs.steam = {
    enable = isDesktop;
    remotePlay.openFirewall = isDesktop;
    dedicatedServer.openFirewall = isDesktop;
    gamescopeSession.enable = isDesktop;
  };

  programs.gamemode.enable = isDesktop;

  environment.systemPackages =
    with pkgs;
    lib.optionals isDesktop [
      goverlay
      heroic
      lutris
      mangohud
      protonup-qt
      vkBasalt
      vulkan-tools
    ];

  hardware.steam-hardware.enable = isDesktop;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
}
