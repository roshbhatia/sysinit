{
  pkgs,
  ...
}:

{
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    protontricks.enable = true;
    extest.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # PipeWire RT config is in audio/default.nix
  programs.gamemode.enable = true;
  hardware.steam-hardware.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # Gaming packages
  environment.systemPackages = with pkgs; [
    mangohud
    vulkan-validation-layers
  ];
}
