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
      macos-hidden = "always";
      macos-titlebar-style = "hidden";
      macos-window-shadow = false;

      window-padding-x = 2;
      window-padding-y = 2;

      background-blur = values.theme.transparency.blur;

      keybind = [
        "clear"
        "global:alt+enter=toggle_quick_terminal"
        "super+;=toggle_command_palette"
        "super+c=copy_to_clipboard"
        "super+minus=decrease_font_size:1"
        "super+plus=increase_font_size:1"
        "super+q=quit"
        "super+v=paste_from_clipboard"
        "super+w=close_surface"
      ];
    };
  };
}
