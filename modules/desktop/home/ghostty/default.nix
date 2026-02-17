{ config, ... }:

{
  stylix.targets.ghostty = {
    enable = true;
  };

  programs.ghostty = {
    enable = true;
    settings = {
      macos-titlebar-style = "hidden";

      background-opacity = config.sysinit.theme.transparency.opacity;
      background-opacity-cells = true;
      background-blur = true;

      window-padding-x = 8;
      window-padding-y = 8;
      window-padding-balance = true;

      keybind = [
        "super+h=toggle_visibility"
        "super+q=quit"
        "super+w=close_tab"
        "global:alt+enter=toggle_quick_terminal"
        "performable:super+c=copy_to_clipboard"
        "performable:super+v=paste_from_clipboard"
        "super+plus=paste_from_clipboard"
        "super+v=paste_from_clipboard"
        "super+z=undo"
        "super+shift+z=redo"
      ];
    };
  };
}
