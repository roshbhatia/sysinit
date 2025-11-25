{
  config,
  pkgs,
  lib,
  ...
}:
{
  # arrakis - Gaming Desktop (x86_64-linux)
  # Windows desktop being migrated to NixOS

  # Enable X11 for gaming
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # Gaming-specific configuration
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Enable GameMode for better gaming performance
  programs.gamemode.enable = true;

  # Gaming packages
  environment.systemPackages = with pkgs; [
    # Game launchers
    steam
    lutris
    heroic

    # Gaming tools
    mangohud
    gamemode

    # Emulators (optional)
    # retroarch
  ];

  # Enable 32-bit support for games
  hardware.opengl.driSupport32Bit = true;
  hardware.pulseaudio.support32Bit = true;

  # Open firewall ports for gaming
  networking.firewall = {
    allowedTCPPorts = [
      # Steam
      27036
      27037
    ];
    allowedUDPPorts = [
      # Steam
      27031
      27036
    ];
  };
}
