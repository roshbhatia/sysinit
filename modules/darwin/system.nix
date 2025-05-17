{
  pkgs,
  lib,
  username,
  homeDirectory,
  userConfig ? { },
  enableHomebrew,
  ...
}:

let
  activationUtils = import ../lib/activation-utils.nix { inherit lib; };
  packageLib = import ../lib/packages.nix { inherit pkgs lib; };
in
{
  system = {
    primaryUser = username;
    defaults = {
      alf = {
        allowdownloadsignedenabled = 0;
      };
      dock = {
        autohide = true;
        expose-group-apps = true;
        launchanim = true;
        mineffect = "scale";
        mru-spaces = false;
        orientation = "bottom";
        persistent-others = [ ];
        show-recents = false;
        tilesize = 30;
      };
      LaunchServices.LSQuarantine = false;
      finder = {
        _FXShowPosixPathInTitle = true;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        CreateDesktop = false;
        FXDefaultSearchScope = "SCcf";
        QuitMenuItem = true;
        ShowPathbar = true;
      };
      NSGlobalDomain = {
        "com.apple.sound.beep.feedback" = 0;
        AppleInterfaceStyle = "Dark";
        ApplePressAndHoldEnabled = false;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        AppleShowScrollBars = "Always";
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        NSWindowShouldDragOnGesture = true;
      };
      spaces = {
        spans-displays = false;
      };
    };

    # Required for nix-darwin
    stateVersion = 4;
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [ "https://cache.nixos.org/" ];
      trusted-users = [
        "root"
        username
      ];
    };
    enable = false;
  };

  environment.systemPackages = lib.mkIf (!enableHomebrew) packageLib.systemPackages;
  environment.extraInit = packageLib.extraInit;

  launchd.agents.colima = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.colima}/bin/colima"
        "start"
      ];
      EnvironmentVariables = {
        HOME = homeDirectory;
        XDG_CONFIG_HOME = "${homeDirectory}/.config";
      };
      RunAtLoad = true;
      KeepAlive = {
        Crashed = true;
        SuccessfulExit = false;
      };
      ProcessType = "Interactive";
      StandardOutPath = "${homeDirectory}/.local/state/colima/daemon.log";
      StandardErrorPath = "${homeDirectory}/.local/state/colima/daemon.error.log";
    };
  };

  users.users.${username}.home = homeDirectory;

  security.pam.services.sudo_local.touchIdAuth = true;
}

