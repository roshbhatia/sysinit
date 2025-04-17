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
        _FXShowPosixPathInTitle = true;
      };
      LaunchServices.LSQuarantine = false;
    };

    # Required for nix-darwin
    stateVersion = 4;
  };

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      substituters = ["https://cache.nixos.org/"];
      trusted-users = ["root" username];
    };
    enable = false;
  };

  launchd.agents.colima = {
    enable = true;
    serviceConfig = {
      ProgramArguments = [ "${pkgs.colima}/bin/colima" "start" ];
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

  system.activationScripts.postUserActivation.text = ''  
    # Install Rosetta 2 for M1/M2 Mac compatibility
    if [[ "$(uname -m)" == "arm64" ]] && ! /usr/bin/pgrep -q "oahd"; then
      echo "Installing Rosetta 2 for Intel app compatibility..."
      /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    fi
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}
