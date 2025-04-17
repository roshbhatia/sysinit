{ pkgs, lib, username, homeDirectory, userConfig ? {}, ... }:

{
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
        expose-group-apps = true;
        launchanim = true;
        mru-spaces = false;
        orientation = "bottom";
        persistent-others = [];
        show-recents = false;
        tilesize = 30;
        mineffect = "scale";
      };
      spaces = {
        spans-displays = false;
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
      trusted-users = ["root" username];
    };
    # Disable internal nix-daemon management since Determinate Nix manages it
    enable = false;
  };

  # Used for backwards compatibility
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Required to avoid sandbox build issues
  users.users.${username}.home = homeDirectory;
  
  # Enable Touch ID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;

  system.activationScripts.postUserActivation.text = ''  
    # Install Rosetta 2 for M1/M2 Mac compatibility
    if [[ "$(uname -m)" == "arm64" ]] && ! /usr/bin/pgrep -q "oahd"; then
      echo "Installing Rosetta 2 for Intel app compatibility..."
      /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    fi

    # Check and manage Colima service
    if ! brew services start colima 2>/dev/null; then
      echo "Restarting Colima service..."
      brew services restart colima
    fi
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}
