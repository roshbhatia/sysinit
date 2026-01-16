{
  pkgs,
  ...
}:

let
  cursorTailShader = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/sahaj-b/ghostty-cursor-shaders/main/cursor_tail.glsl";
    sha256 = "1g9vsbsxnvcj0y6rzdkxrd4mj0ldl9aha7381g8nfs3bz829y46w";
  };
in
{
  stylix.targets.ghostty.enable = true;

  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then null else pkgs.ghostty;

    settings = {
      macos-hidden = "always";
      macos-window-shadow = false;

      window-padding-x = 2;
      window-padding-y = 2;

      custom-shader = "${cursorTailShader}";

      keybind = [
        "clear"
        "global:alt+enter=toggle_quick_terminal"
        "super+;=toggle_command_palette"
        "super+a=select_all"
        "super+c=copy_to_clipboard"
        "super+minus=decrease_font_size:1"
        "super+plus=increase_font_size:1"
        "super+v=paste_from_clipboard"
        "super+w=close_surface"
      ];
    };
  };
}
