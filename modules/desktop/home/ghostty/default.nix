{
  config,
  pkgs,
  ...
}:

{
  stylix.targets.ghostty = {
    enable = true;
  };

  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then null else pkgs.ghostty;

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
        "super+1=goto_tab:1"
        "super+2=goto_tab:2"
        "super+3=goto_tab:3"
        "super+4=goto_tab:4"
        "super+5=goto_tab:5"
        "super+6=goto_tab:6"
        "super+7=goto_tab:7"
        "super+8=goto_tab:8"
        "super+9=goto_tab:9"
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
