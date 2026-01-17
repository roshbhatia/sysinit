{
  pkgs,
  values,
  ...
}:

{
  stylix.targets.ghostty.enable = true;

  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then null else pkgs.ghostty;

    settings = {
      background-blur = values.theme.transparency.blur;
      window-padding-x = 4;
      window-padding-y = "2,3";
      window-padding-balance = true;
      font-size = 13;

      macos-hidden = "always";
      macos-titlebar-style = "hidden";

      command = "${pkgs.zellij}/bin/zellij";

      keybind = [
        "clear"
        "global:alt+enter=toggle_quick_terminal"
        "super+;=toggle_command_palette"
        "super+c=copy_to_clipboard"
        "super+minus=decrease_font_size:1"
        "super+plus=increase_font_size:1"
        "super+q=quit"
        "super+n=new_window"
        "super+v=paste_from_clipboard"
        "super+w=close_surface"
      ];
    };
  };
}
