{ pkgs, lib, ... }: {
  environment.variables.EDITOR = "code --wait";

  system = {
    defaults = {
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        AppleShowScrollBars = "Always";
        KeyRepeat = 2;
        InitialKeyRepeat = 15;
      };
      dock = {
        autohide = false;
        launchanim = true;
        mru-spaces = false;
        orientation = "bottom";
        persistent-others = [];
        show-recents = false;
        tilesize = 20;
      };
      finder = {
        AppleShowAllExtensions = true;
        QuitMenuItem = true;
        ShowPathbar = true;
        _FXShowPosixPathInTitle = true; # Use proper option name
      };
      LaunchServices.LSQuarantine = false;
    };

    # Required for nix-darwin
    stateVersion = 4;
  };

  # Nix configuration - using Determinate Nix
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      substituters = ["https://cache.nixos.org/"];
    };
    # Disable internal nix-daemon management since Determinate Nix manages it
    enable = false;
  };

  # Used for backwards compatibility
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Required to avoid sandbox build issues
  users.users.${builtins.getEnv "USER"}.home = builtins.getEnv "HOME";
  
  # Enable Touch ID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;

  system.activationScripts.postUserActivation.text = ''  
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}
