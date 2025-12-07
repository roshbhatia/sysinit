{
  values,
  ...
}:
{
  system.defaults = {
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
      AppleInterfaceStyle = if values.theme.appearance == "dark" then "Dark" else null;
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
  };
}
