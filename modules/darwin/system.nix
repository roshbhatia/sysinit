{ pkgs, lib, username, homeDirectory, userConfig ? {}, ... }:

let
  # Use wallpaper from userConfig
  wallpaperPath = "${homeDirectory}/.wallpaper";
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
    # Check and manage Colima service
    if ! brew services start colima 2>/dev/null; then
      echo "Restarting Colima service..."
      brew services restart colima
    fi

    # Replace the bashrc with our fixed version
    echo "Replacing /etc/bashrc..."
    sudo cp ${./bashrc-fix.sh} /etc/bashrc
    sudo chmod 644 /etc/bashrc

    # Make sure gettext is properly linked
    if [ -d "/opt/homebrew/opt/gettext/bin" ]; then
      echo "Creating gettext symlinks..."
      sudo ln -sf /opt/homebrew/opt/gettext/bin/gettext /usr/local/bin/gettext 2>/dev/null || true
    fi

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
  
  environment.etc.bashrc.text = lib.mkAfter ''
    # Fix TERM_PROGRAM unbound variable issue
    if [ -z "$TERM_PROGRAM" ]; then
      export TERM_PROGRAM=""
    fi
  '';
}
