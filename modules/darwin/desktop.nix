{ config, ... }:

{
  system = {
    defaults = {
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
        wvous-br-corner = 1;
      };

      finder = {
        _FXShowPosixPathInTitle = true;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        CreateDesktop = false;
        FXDefaultSearchScope = "SCcf";
        QuitMenuItem = true;
        ShowPathbar = true;
      };

      menuExtraClock = {
        ShowAMPM = true;
        ShowDate = 0;
        ShowDayOfWeek = true;
      };

      trackpad = {
        Clicking = false;
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = false;
      };

      NSGlobalDomain = {
        "com.apple.sound.beep.feedback" = 0;
        AppleInterfaceStyle = if config.sysinit.theme.appearance == "dark" then "Dark" else null;
        ApplePressAndHoldEnabled = false;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        AppleShowScrollBars = "Always";
        AppleSpacesSwitchOnActivate = false;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        NSAutomaticWindowAnimationsEnabled = false;
        NSWindowShouldDragOnGesture = true;
        _HIHideMenuBar = true;
      };

      CustomUserPreferences = {
        "NSGlobalDomain" = {
          AppleActionOnDoubleClick = "None";
          "com.apple.sound.beep.flash" = 0;
          "com.apple.springing.enabled" = true;
          "com.apple.springing.delay" = 0.5;
          "com.apple.trackpad.forceClick" = 1;
        };
        "com.apple.dock" = {
          "wvous-br-modifier" = 0;
        };
        "com.apple.finder" = {
          ShowSidebar = true;
        };
      };
    };

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };
}
