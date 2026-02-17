{ config, ... }:

{
  system.defaults.dock = {
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

  system.defaults.finder = {
    _FXShowPosixPathInTitle = true;
    AppleShowAllExtensions = true;
    AppleShowAllFiles = true;
    CreateDesktop = false;
    FXDefaultSearchScope = "SCcf";
    QuitMenuItem = true;
    ShowPathbar = true;
  };

  system.defaults.NSGlobalDomain = {
    "com.apple.sound.beep.feedback" = 0;
    AppleInterfaceStyle = if config.sysinit.theme.appearance == "dark" then "Dark" else null;
    ApplePressAndHoldEnabled = false;
    AppleShowAllExtensions = true;
    AppleShowAllFiles = true;
    AppleShowScrollBars = "Always";
    InitialKeyRepeat = 15;
    KeyRepeat = 2;
    NSAutomaticWindowAnimationsEnabled = false;
    NSWindowShouldDragOnGesture = true;
    _HIHideMenuBar = true;
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };
}
