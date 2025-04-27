{ pkgs, lib, username, homeDirectory, userConfig ? {}, enableHomebrew, ... }:

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
        persistent-others = [];
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
        _HIHideMenuBar = true;
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
      experimental-features = ["nix-command" "flakes"];
      substituters = ["https://cache.nixos.org/"];
      trusted-users = ["root" username];
    };
    enable = false;
  };
  
  # Migrate common CLI tools from Homebrew to Nix when Homebrew is disabled
  environment.systemPackages = lib.mkIf (!enableHomebrew) (with pkgs; [
    argocd
    ansible
    caddy
    colima
    direnv
    eza
    fd
    glow
    gum
    gettext
    helm
    oh-my-posh
    kubectl
    kubecolor
    k9s
    lazygit
    libgit2
    luajit
    nil
    nixfmt-rfc-style
    nushell
    pipx
    python3
    ripgrep
    screenresolution
    shellcheck
    socat
    sshpass
    tailscale
    go-task
    yazi
  ]);

  launchd.agents.colima = {
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
  # Ensure user owns /usr/local/bin for easy management without sudo
  system.activationScripts.fixUsrLocalBin = {
    text = ''
      if [ -d /usr/local/bin ]; then
        echo "Fixing ownership of /usr/local/bin"
        chown -R ${username} /usr/local/bin || true
      fi
    '';
  };
}
