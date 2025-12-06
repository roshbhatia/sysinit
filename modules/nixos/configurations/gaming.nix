{
  pkgs,
  ...
}:

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
    NIXOS_OZONE_WL = "1";
  };
}
