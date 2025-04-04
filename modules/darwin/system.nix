{ pkgs, lib, username, homeDirectory, userConfig ? {}, ... }:

let
  # Use wallpaper from the system location
  wallpaperPath = "${../..}/wall/pain.jpeg";
in {
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

    # Create an empty bashrc to prevent issues
    echo "Creating minimal /etc/bashrc..."
    echo '#!/bin/bash
# Minimal bashrc
export TERM_PROGRAM=""
# Skip this file entirely
return 0' | sudo tee /etc/bashrc > /dev/null
    sudo chmod 644 /etc/bashrc

    # No need for manual symlink creation
    # Python and gettext will be handled by Homebrew directly

    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    
    # Set wallpaper with simple osascript approach
    echo "Setting desktop wallpaper..."
    if [ -f "${wallpaperPath}" ]; then
      /usr/bin/osascript <<EOF
        tell application "System Events"
          tell every desktop
            set picture to "${wallpaperPath}"
          end tell
        end tell
EOF
      echo "Wallpaper set successfully!"
    else
      echo "Wallpaper file not found: ${wallpaperPath}"
    fi
  '';
  
  # Fix TERM_PROGRAM unbound variable in shell init files
  environment.etc.zshrc.text = lib.mkAfter ''
    # Fix TERM_PROGRAM unbound variable issue
    if [ -z "$TERM_PROGRAM" ]; then
      export TERM_PROGRAM=""
    fi
  '';
  
  # Disable bash completely
  programs.bash.enable = false;
}
