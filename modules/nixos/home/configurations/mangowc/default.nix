{
  lib,
  values,
  pkgs,
  ...
}:

let
  themes = import ../../../../shared/lib/theme { inherit lib; };
  theme = themes.getTheme values.theme.colorscheme;
  palette = theme.palettes.${values.theme.variant};
in

{
  wayland.windowManager.mangowc = {
    enable = true;
    package = pkgs.mangowc;

    settings = {
      # Display and output configuration
      outputs = [
        {
          name = "*";
          scale = 1;
          transform = "normal";
          enable = true;
        }
      ];

      # Input configuration
      input = {
        kb_layout = "us";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        repeat_delay = 200;
        repeat_rate = 50;
        touchpad = {
          tap = true;
          natural_scroll = false;
        };
      };

      # Retroism color scheme
      colors = {
        background = palette.bg0;
        foreground = palette.fg0;
        border_active = palette.accent;
        border_inactive = palette.bg3;
        text = palette.fg0;
        accent = palette.cyan;
      };

      # Window management
      window_management = {
        gaps_inner = 4;
        gaps_outer = 8;
        border_width = 2;
        focus_follows_mouse = true;
        snap_to_edge = true;
      };

      # Layout modes
      layouts = [
        "tiling"
        "tabbed"
        "floating"
      ];
      default_layout = "tiling";

      # Workspaces
      workspaces = [
        { name = "1"; }
        { name = "2"; }
        { name = "3"; }
        { name = "4"; }
        { name = "5"; }
        { name = "6"; }
        { name = "7"; }
        { name = "8"; }
        { name = "9"; }
      ];

      # Keybindings
      keybindings = [
        # Focus movement
        { key = ["Super" "h"]; command = "focus left"; }
        { key = ["Super" "j"]; command = "focus down"; }
        { key = ["Super" "k"]; command = "focus up"; }
        { key = ["Super" "l"]; command = "focus right"; }

        # Move windows
        { key = ["Super" "Shift" "h"]; command = "move left"; }
        { key = ["Super" "Shift" "j"]; command = "move down"; }
        { key = ["Super" "Shift" "k"]; command = "move up"; }
        { key = ["Super" "Shift" "l"]; command = "move right"; }

        # Workspaces
        { key = ["Super" "1"]; command = "workspace 1"; }
        { key = ["Super" "2"]; command = "workspace 2"; }
        { key = ["Super" "3"]; command = "workspace 3"; }
        { key = ["Super" "4"]; command = "workspace 4"; }
        { key = ["Super" "5"]; command = "workspace 5"; }
        { key = ["Super" "6"]; command = "workspace 6"; }
        { key = ["Super" "7"]; command = "workspace 7"; }
        { key = ["Super" "8"]; command = "workspace 8"; }
        { key = ["Super" "9"]; command = "workspace 9"; }

        # Move to workspace
        { key = ["Super" "Shift" "1"]; command = "move container to workspace 1"; }
        { key = ["Super" "Shift" "2"]; command = "move container to workspace 2"; }
        { key = ["Super" "Shift" "3"]; command = "move container to workspace 3"; }
        { key = ["Super" "Shift" "4"]; command = "move container to workspace 4"; }
        { key = ["Super" "Shift" "5"]; command = "move container to workspace 5"; }
        { key = ["Super" "Shift" "6"]; command = "move container to workspace 6"; }
        { key = ["Super" "Shift" "7"]; command = "move container to workspace 7"; }
        { key = ["Super" "Shift" "8"]; command = "move container to workspace 8"; }
        { key = ["Super" "Shift" "9"]; command = "move container to workspace 9"; }

        # Window management
        { key = ["Super" "f"]; command = "fullscreen toggle"; }
        { key = ["Super" "q"]; command = "kill"; }
        { key = ["Super" "space"]; command = "floating toggle"; }

        # Applications
        { key = ["Super" "t"]; command = "exec wezterm"; }
        { key = ["Super" "d"]; command = "exec wofi --show=drun"; }
        { key = ["Super" "s"]; command = "exec grim -g \"$(slurp)\" - | swappy -f -"; }

        # System
        { key = ["Super" "Escape"]; command = "exit"; }
      ];

      # Startup commands
      autostart = [
        "test -f ~/.config/mangowc/background.png && swaybg -i ~/.config/mangowc/background.png"
        "waybar"
        "mako"
      ];

      # Font configuration
      font = {
        family = values.theme.font.monospace;
        size = 10;
      };
    };
  };

  # Ensure required packages are available
  home.packages = with pkgs; [
    swaybg
    wayland
  ];
}
