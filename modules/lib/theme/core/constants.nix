{ lib }:

let
  presets = import ./presets.nix { inherit lib; };
in

{
  supportedApps = [
    "neovim"
    "wezterm"
    "bat"
    "git"
    "atuin"
    "vivid"
    "helix"
    "k9s"
  ];

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

  # Re-export transparency presets from core/presets.nix for backward compatibility
  inherit (presets) transparencyPresets;
}
