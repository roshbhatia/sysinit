{
  values,
  lib,
  ...
}:

let
  themeNames = import ../../../shared/lib/theme/adapters/theme-names.nix { inherit lib; };
  themeName = themeNames.getKittyTheme values.theme.colorscheme values.theme.variant;
in
{
  programs.kitty = {
    enable = true;
    settings = {
      # Theme
      include = "${themeName}.conf";

      # Appearance
      confirm_os_window_close = 1;
      background_opacity = values.theme.transparency.opacity;
      background_blur = if values.theme.transparency.enable then values.theme.transparency.blur else 0;
      hide_window_decorations = "titlebar-only";
      macos_hide_from_tasks = false;

      # Window
      window_padding_width = 8;
      window_margin_width = 0;
      window_border_width = 0;
      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";

      # Bell
      visual_bell_duration = "0.1";

      # Cursor
      cursor_blink_interval = 330;
      cursor_shape = "beam";
      cursor_beam_thickness = 1;

      # Scrollback
      scrollback_lines = 10000;

      # Mouse
      mouse_hide_wait = 0;
      url_color = "#0087be";
      url_style = "curly";
      copy_on_select = "clipboard";

      # Performance
      sync_to_monitor = true;

      # Layouts
      enabled_layouts = "tall,grid,stack,vertical";

      # Shell
      shell = "/etc/profiles/per-user/$USER/bin/zsh --login";
    };

    keybindings = {
      # Panes
      "ctrl+s" = "new_window";
      "ctrl+v" = "new_tab";

      # Navigation
      "ctrl+h" = "neighboring_window left";
      "ctrl+l" = "neighboring_window right";
      "ctrl+k" = "neighboring_window up";
      "ctrl+j" = "neighboring_window down";

      # Resize panes
      "ctrl+shift+h" = "resize_window narrower";
      "ctrl+shift+l" = "resize_window wider";
      "ctrl+shift+k" = "resize_window taller";
      "ctrl+shift+j" = "resize_window shorter";
      "ctrl+shift+Home" = "resize_window reset";

      # Close
      "ctrl+w" = "close_window";
      "ctrl+shift+w" = "close_tab";

      # Tabs
      "ctrl+t" = "new_tab";
      "ctrl+shift+Tab" = "move_tab_backward";
      "ctrl+Tab" = "move_tab_forward";
      "ctrl+shift+o" = "select_tab";
      "ctrl+1" = "goto_tab 1";
      "ctrl+2" = "goto_tab 2";
      "ctrl+3" = "goto_tab 3";
      "ctrl+4" = "goto_tab 4";
      "ctrl+5" = "goto_tab 5";
      "ctrl+6" = "goto_tab 6";
      "ctrl+7" = "goto_tab 7";
      "ctrl+8" = "goto_tab 8";
      "ctrl+9" = "goto_tab -1";

      # Font size
      "ctrl+minus" = "change_font_size all -1.0";
      "super+minus" = "change_font_size all -1.0";
      "ctrl+equal" = "change_font_size all 1.0";
      "super+equal" = "change_font_size all 1.0";

      # Scrollback
      "ctrl+u" = "scroll_line_up -40";
      "ctrl+shift+u" = "scroll_page_up";
      "ctrl+d" = "scroll_line_down 40";
      "ctrl+shift+d" = "scroll_page_down";

      # Search
      "ctrl+slash" = "show_scrollback";
      "ctrl+f" =
        "launch --type overlay --stdin-source=@screen_scrollback fzf --no-sort --no-mouse --exact -i";

      # System (macOS)
      "super+c" = "copy_to_clipboard";
      "super+v" = "paste_from_clipboard";
      "super+m" = "hide_macos_app";
      "super+h" = "hide_macos_app";
      "super+q" = "quit";
      "super+k" = "send_text all \\u001b[3J";

      # Copy mode
      "ctrl+Escape" = "enter_copy_mode";

      # Other
      "ctrl+shift+l" = "show_last_command_output";
      "ctrl+shift+semicolon" = "toggle_maximized";
      "ctrl+shift+r" = "reload_config_file";
    };
  };

  xdg.configFile = {
    "kitty/symbol_map.conf".text = ''
      symbol_map U+E000-U+E00A,U+EA60-U+EBEB,U+E0A0-U+E0C8,U+E0D4,U+2665,U+26A1,U+2B58 ${values.theme.font.symbols}
    '';
  };
}
