{
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  zellijTheme = themes.getAppTheme "zellij" values.theme.colorscheme values.theme.variant;
in
{
  programs.zellij = {
    enable = true;
    settings = {
      theme = zellijTheme;
      pane_frames = false;
      simplified_ui = true;

      scrollback_editor = "nvim";
      scroll_buffer_size = 50000;

      mouse_mode = true;

      copy_command = "pbcopy";
      copy_clipboard = "primary";

      scrollback_lines_to_serialize = 100000;
      on_force_close = "detach";

      plugins = {
        zjstatus-hints = {
          location = "https://github.com/b0o/zjstatus-hints/releases/latest/download/zjstatus-hints.wasm";
          max_length = 50;
          overflow_str = "...";
          pipe_name = "zjstatus_hints";
          hide_in_base_mode = false;
        };
        session-manager = {
          location = "zellij:session-manager";
        };
        status-bar = {
          location = "zellij:status-bar";
        };
      };
      load_plugins = [
        "zjstatus-hints"
        "session-manager"
        "status-bar"
      ];
      keybinds = {
        _props = {
          clear-defaults = true;
        };
        normal = [
          {
            bind = "Ctrl h";
            MoveFocus = "left";
          }
          {
            bind = "Ctrl j";
            MoveFocus = "down";
          }
          {
            bind = "Ctrl k";
            MoveFocus = "up";
          }
          {
            bind = "Ctrl l";
            MoveFocus = "right";
          }
          {
            bind = "Ctrl Shift h";
            Resize = "Increase left";
          }
          {
            bind = "Ctrl Shift j";
            Resize = "Increase down";
          }
          {
            bind = "Ctrl Shift k";
            Resize = "Increase up";
          }
          {
            bind = "Ctrl Shift l";
            Resize = "Increase right";
          }
          {
            bind = "Ctrl v";
            NewPane = "right";
          }
          {
            bind = "Ctrl s";
            NewPane = "down";
          }
          {
            bind = "Ctrl w";
            CloseFocus = { };
          }
          {
            bind = "Ctrl t";
            NewTab = { };
          }
          {
            bind = "Ctrl 1";
            GoToTab = 1;
          }
          {
            bind = "Ctrl 2";
            GoToTab = 2;
          }
          {
            bind = "Ctrl 3";
            GoToTab = 3;
          }
          {
            bind = "Ctrl 4";
            GoToTab = 4;
          }
          {
            bind = "Ctrl 5";
            GoToTab = 5;
          }
          {
            bind = "Ctrl 6";
            GoToTab = 6;
          }
          {
            bind = "Ctrl 7";
            GoToTab = 7;
          }
          {
            bind = "Ctrl 8";
            GoToTab = 8;
          }
          {
            bind = "Super t";
            NewTab = { };
          }
          {
            bind = "Super 1";
            GoToTab = 1;
          }
          {
            bind = "Super 2";
            GoToTab = 2;
          }
          {
            bind = "Super 3";
            GoToTab = 3;
          }
          {
            bind = "Super 4";
            GoToTab = 4;
          }
          {
            bind = "Super 5";
            GoToTab = 5;
          }
          {
            bind = "Super 6";
            GoToTab = 6;
          }
          {
            bind = "Super 7";
            GoToTab = 7;
          }
          {
            bind = "Super 8";
            GoToTab = 8;
          }
          {
            bind = "Super Shift Left";
            GoToPreviousTab = { };
          }
          {
            bind = "Super Shift Right";
            GoToNextTab = { };
          }
          {
            bind = "h";
            MoveFocus = "left";
          }
          {
            bind = "j";
            MoveFocus = "down";
          }
          {
            bind = "k";
            MoveFocus = "up";
          }
          {
            bind = "l";
            MoveFocus = "right";
          }
          {
            bind = "|";
            NewPane = "right";
          }
          {
            bind = "-";
            NewPane = "down";
          }
          {
            bind = "x";
            CloseFocus = { };
          }
          {
            bind = "1";
            GoToTab = 1;
          }
          {
            bind = "2";
            GoToTab = 2;
          }
          {
            bind = "3";
            GoToTab = 3;
          }
          {
            bind = "4";
            GoToTab = 4;
          }
          {
            bind = "5";
            GoToTab = 5;
          }
          {
            bind = "t";
            NewTab = { };
          }
          {
            bind = "r";
            SwitchToMode = "resize";
          }
          {
            bind = "s";
            SwitchToMode = "scroll";
          }
          {
            bind = "q";
            Quit = { };
          }
        ];
        resize = [
          {
            bind = "h";
            Resize = "Increase left";
          }
          {
            bind = "j";
            Resize = "Increase down";
          }
          {
            bind = "k";
            Resize = "Increase up";
          }
          {
            bind = "l";
            Resize = "Increase right";
          }
          {
            bind = "Esc";
            SwitchToMode = "normal";
          }
        ];
        scroll = [
          {
            bind = "j";
            ScrollDown = { };
          }
          {
            bind = "k";
            ScrollUp = { };
          }
          {
            bind = "Esc";
            SwitchToMode = "normal";
          }
        ];
      };
    };
  };

  xdg.configFile."zellij/zellij.sh" = {
    source = ./zellij.sh;
  };
}
