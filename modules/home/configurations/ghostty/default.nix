{
  pkgs,
  ...
}:

{
  stylix.targets.ghostty.enable = true;

  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then null else pkgs.ghostty;

    settings = {
      macos-hidden = true;
      macos-window-shadow = false;

      quick-terminal-position = "center";
      quick-terminal-size = "60%";

      window-padding-x = 2;
      window-padding-y = 2;

      keybind = [
        "clear"
        "ctrl+d=scroll_page_down"
        "ctrl+shift+;=toggle_command_palette"
        "ctrl+u=scroll_page_up"
        "global:alt+enter=toggle_quick_terminal"
        "super+a=select_all"
        "super+c=copy_to_clipboard"
        "super+k=clear_screen"
        "super+minus=decrease_font_size:1"
        "super+plus=increase_font_size:1"
        "super+v=paste_from_clipboard"
        "super+w=close_surface"
      ];
    };
  };
}
