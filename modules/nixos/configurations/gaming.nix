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

  config = lib.mkIf isDesktop {
    # ==========================================================================
    # Gaming on Linux
    #
    # Steam and Heroic Launcher for gaming
    # https://www.protondb.com/ - Check game compatibility
    # https://www.reddit.com/r/linux_gaming/wiki/faq/ - Beginners guide
    # ==========================================================================

    # Steam - Native and Proton games
    # https://github.com/NixOS/nixpkgs/blob/master/doc/packages/steam.section.md
    programs.steam = {
      enable = true;
      # Run GameScope driven Steam session for better performance
      gamescopeSession.enable = true;
      # Protontricks wrapper for Proton-enabled games
      protontricks.enable = true;
      # Steam Input on Wayland support
      extest.enable = true;
      # Enable remote play and dedicated server support
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };

    # Low-latency audio for better gaming experience
    services.pipewire = {
      extraConfig.pipewire = {
        "context.modules" = [
          {
            name = "libpipewire-module-rt";
            args = {
              "nice.level" = -15;
              "rt.prio" = 88;
              "rt.time.soft" = 200000;
              "rt.time.hard" = 200000;
            };
            flags = [
              "ifexists"
              "nofail"
            ];
          }
        ];
      };
    };

    # GameMode - Optimise Linux system performance on demand
    # https://github.com/FeralInteractive/GameMode
    # Auto-activates for games with GameMode integration
    programs.gamemode.enable = true;

    # Gaming packages
    environment.systemPackages = with pkgs; [
      # Heroic Games Launcher - GOG, Epic Games Store, Amazon Prime Games
      (heroic.override {
        extraPkgs = pkgs: [ pkgs.gamescope ];
      })
      # Lutris - Game launcher/manager
      lutris
      # Manage Proton versions
      protonup-qt
      # Performance monitoring overlay
      mangohud
      # GPU overlay
      goverlay
      # Vulkan tools
      vulkan-tools
      # Post-process enhancements
      vkBasalt
    ];

    # Steam hardware support
    hardware.steam-hardware.enable = true;

    # Wayland support for games
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };
}
