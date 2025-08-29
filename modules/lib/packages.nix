{ platform, pkgs, ... }:
let
  platformPackages =
    if platform.platform.isDarwin then
      {
        windowManager = [ "aerospace" ];
        terminalEmulator = [ "wezterm" ];
        browser = [ "firefox" ];
        systemTools = [
          "borders"
        ];
      }
    else
      {
        windowManager = with pkgs; [
          sway
        ];
        terminalEmulator = with pkgs; [
          wezterm
        ];
        browser = with pkgs; [
          firefox
        ];
        systemTools = with pkgs; [
          xorg.xwininfo
          wmctrl
        ];
      };
in
{
  inherit platformPackages;
}
