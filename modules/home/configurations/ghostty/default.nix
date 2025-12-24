{
  pkgs,
  values,
  lib,
  ...
}:

let
  themes = import ../../../shared/lib/theme { inherit lib; };

  cursorTailShader = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/sahaj-b/ghostty-cursor-shaders/main/cursor_tail.glsl";
    sha256 = "1g9vsbsxnvcj0y6rzdkxrd4mj0ldl9aha7381g8nfs3bz829y46w";
  };

  inherit (values.theme)
    colorscheme
    variant
    transparency
    font
    appearance
    ;
  palette = themes.getThemePalette colorscheme variant;

  stripHash = color: lib.removePrefix "#" color;

  iconFrame = if appearance == "dark" then "plastic" else "aluminum";

  iconGhostColor = stripHash palette.accent;

  accentSecondary =
    palette.accent_secondary or palette.blue or palette.cyan or palette.teal or palette.accent;
  accentTertiary =
    palette.accent_tertiary or palette.purple or palette.mauve or palette.magenta or palette.accent;

  iconScreenColors = lib.concatStringsSep "," [
    (stripHash palette.accent)
    (stripHash accentSecondary)
    (stripHash accentTertiary)
  ];
in
{
  stylix.targets.ghostty = {
    enable = true;
  };

  programs.ghostty = {
    enable = true;
    settings = {
      auto-update-channel = "tip";
      custom-shader = "${cursorTailShader}";

      font-size = 13;
      window-padding-x = "10";
      window-padding-y = "10,5";

      background-opacity = transparency.opacity;
      background-blur-radius = 20;

      macos-titlebar-style = "hidden";
      window-title-font-family = font.monospace;

      macos-icon = "custom-style";
      macos-icon-frame = iconFrame;
      macos-icon-ghost-color = iconGhostColor;
      macos-icon-screen-color = iconScreenColors;

      quick-terminal-position = "top";
      shell-integration = "detect";

      keybind = [
        "alt+enter=global:toggle_quick_terminal"

        # New tab (both ctrl and cmd)
        "ctrl+t=new_tab"
        "super+t=new_tab"

        # New window (both ctrl and cmd)
        "ctrl+n=new_window"
        "super+n=new_window"

        # Tab navigation (ctrl+number and cmd+number)
        "ctrl+one=goto_tab:1"
        "ctrl+two=goto_tab:2"
        "ctrl+three=goto_tab:3"
        "ctrl+four=goto_tab:4"
        "ctrl+five=goto_tab:5"
        "ctrl+six=goto_tab:6"
        "ctrl+seven=goto_tab:7"
        "ctrl+eight=goto_tab:8"
        "ctrl+nine=goto_tab:9"
        "super+one=goto_tab:1"
        "super+two=goto_tab:2"
        "super+three=goto_tab:3"
        "super+four=goto_tab:4"
        "super+five=goto_tab:5"
        "super+six=goto_tab:6"
        "super+seven=goto_tab:7"
        "super+eight=goto_tab:8"
        "super+nine=goto_tab:9"

        # macOS standard keybinds
        "super+w=close_surface"
        "super+q=quit"
        "super+h=toggle_visibility"
        "super+m=toggle_visibility"

        # Vim mode
        "ctrl+escape=activate_key_table:vim"

        "vim/"

        "vim/space>space=toggle_command_palette"
        "vim/shift+semicolon=toggle_command_palette"

        # Line movement
        "vim/j=scroll_page_lines:1"
        "vim/k=scroll_page_lines:-1"

        # Page movement
        "vim/ctrl+d=scroll_page_down"
        "vim/ctrl+u=scroll_page_up"
        "vim/ctrl+f=scroll_page_down"
        "vim/ctrl+b=scroll_page_up"
        "vim/shift+j=scroll_page_down"
        "vim/shift+k=scroll_page_up"

        # Jump to top/bottom
        "vim/g>g=scroll_to_top"
        "vim/shift+g=scroll_to_bottom"

        # Search
        "vim/slash=start_search"
        "vim/n=navigate_search:next"

        # Copy mode / selection
        "vim/v=copy_to_clipboard"
        "vim/y=copy_to_clipboard"

        # Command Palette
        "vim/shift+semicolon=toggle_command_palette"

        # Exit vim mode
        "vim/escape=deactivate_key_table"
        "vim/q=deactivate_key_table"
        "vim/i=deactivate_key_table"

        # Catch unbound keys
        "vim/catch_all=ignore"
      ];
    };
  };
}
