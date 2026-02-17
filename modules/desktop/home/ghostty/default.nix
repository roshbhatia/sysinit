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
        "global:alt+enter=toggle_quick_terminal"
        "performable:super+c=copy_to_clipboard"
        "performable:super+v=paste_from_clipboard"
        "super+a=select_all"
        "super+equals=increase_font_size:1"
        "super+h=toggle_visibility"
        "super+minus=decrease_font_size:1"
        "super+n=new_window"
        "super+q=quit"
        "super+shift+z=redo"
        "super+t=new_tab"
        "super+v=paste_from_clipboard"
        "super+w=close_tab"
        "super+z=undo"
      ];
    };
  };
}
