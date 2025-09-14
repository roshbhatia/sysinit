{
  lib,
  pkgs,
  ...
}:

{
  fonts.fontconfig = {
    enable = true;
    antialiasing = "subpixel";
    hinting = "medium";
    subpixelRendering = "rgb";
    defaultFonts = {
      serif = [ "Source Serif Pro" ];
      sansSerif = [ "SF Pro Display" "Inter" ];
      monospace = [ "JetBrainsMono Nerd Font" "FiraCode Nerd Font" ];
      emoji = [ "Apple Color Emoji" "Noto Color Emoji" ];
    };
  };
}
