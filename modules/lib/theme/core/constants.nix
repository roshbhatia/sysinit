{ ... }:

{
  # Default theme configuration
  defaultThemeConfig = {
    colorscheme = "catppuccin";
    variant = "macchiato";
    transparency = {
      enable = true;
      opacity = 0.85;
      blur = 80;
    };
    presets = [ ];
    overrides = { };
  };

  # Supported applications
  supportedApps = [
    "neovim"
    "wezterm"
    "bat"
    "git"
    "atuin"
    "vivid"
    "helix"
    "nushell"
    "k9s"
  ];

  # Standard ANSI color indices
  ansiColorMap = {
    black = 0;
    red = 1;
    green = 2;
    yellow = 3;
    blue = 4;
    magenta = 5;
    cyan = 6;
    white = 7;
    bright_black = 8;
    bright_red = 9;
    bright_green = 10;
    bright_yellow = 11;
    bright_blue = 12;
    bright_magenta = 13;
    bright_cyan = 14;
    bright_white = 15;
  };

  # Common transparency presets
  transparencyPresets = {
    none = {
      enable = false;
      opacity = 1.0;
      blur = 0;
    };
    light = {
      enable = true;
      opacity = 0.95;
      blur = 20;
    };
    medium = {
      enable = true;
      opacity = 0.85;
      blur = 80;
    };
    heavy = {
      enable = true;
      opacity = 0.70;
      blur = 120;
    };
  };

  # Accessibility presets
  accessibilityPresets = {
    high_contrast = {
      # Will be defined later for color modifications
    };
    reduced_motion = {
      # For animations/transitions
    };
  };
}
