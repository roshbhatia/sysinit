{
  username,
  homeDirectory,
  ...
}:

{
  system = {
    primaryUser = username;
    defaults = {
      alf = {
        allowdownloadsignedenabled = 1;
        globalstate = 0;
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
      WindowManager = {
        EnableTilingOptionAccelerator = true;
        StandardHideDesktopIcons = true;
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

  users.users.${username}.home = homeDirectory;

  security.pam.services.sudo_local.touchIdAuth = true;
}
