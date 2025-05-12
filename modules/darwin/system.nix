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
  # Import the activation utils
  activationUtils = import ../lib/activation-utils.nix { inherit lib; };

  # Import the shared package definitions
  packageLib = import ../lib/packages.nix { inherit pkgs lib; };
in
{
  system = {
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
        _HIHideMenuBar = true;
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

  # Migrate common CLI tools from Homebrew to Nix when Homebrew is disabled
  # Packages are defined in modules/lib/packages.nix
  environment.systemPackages = lib.mkIf (!enableHomebrew) packageLib.systemPackages;

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

  # Use our custom activation script format for system activation scripts
  system.activationScripts.postUserActivation.text = ''
    # Setup PATH and logging functions
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH"

    log_info() {
      echo -e "[\033[0;36m$(date '+%Y-%m-%d %H:%M:%S')\033[0m] [\033[0;34mINFO\033[0m] $1"
    }

    log_success() {
      echo -e "[\033[0;36m$(date '+%Y-%m-%d %H:%M:%S')\033[0m] [\033[0;32mSUCCESS\033[0m] $1"
    }

    # Install Rosetta 2 for M1/M2 Mac compatibility
    if [[ "$(uname -m)" == "arm64" ]] && ! /usr/bin/pgrep -q "oahd"; then
      log_info "Installing Rosetta 2 for Intel app compatibility..."
      /usr/sbin/softwareupdate --install-rosetta --agree-to-license
      log_success "Rosetta 2 installed"
    fi

    # Activate settings
    log_info "Activating system settings..."
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    log_success "System settings activated"
  '';

  # Fix /usr/local/bin ownership using our consistent logging
  system.activationScripts.fixUsrLocalBin = {
    text = ''
      export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH"

      log_info() {
        echo -e "[\033[0;36m$(date '+%Y-%m-%d %H:%M:%S')\033[0m] [\033[0;34mINFO\033[0m] $1"
      }

      log_success() {
        echo -e "[\033[0;36m$(date '+%Y-%m-%d %H:%M:%S')\033[0m] [\033[0;32mSUCCESS\033[0m] $1"
      }

      if [ -d /usr/local/bin ]; then
        log_info "Fixing ownership of /usr/local/bin"
        chown -R ${username} /usr/local/bin || true
        log_success "Fixed ownership of /usr/local/bin"
      fi
    '';
  };
}
