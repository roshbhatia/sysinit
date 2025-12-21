{
  lib,
  values,
  pkgs,
  ...
}:

let
  themes = import ../../../../shared/lib/theme { inherit lib; };
  semanticColors = themes.getSemanticColors values.theme.colorscheme values.theme.variant;
in

{
  wayland.windowManager.sway = {
    enable = true;
    package = pkgs.sway;
    systemd.enable = true;

    config = {
      # Display configuration
      output = {
        "*" = {
          bg = "#${lib.strings.removePrefix "#" semanticColors.background.primary} solid_color";
        };
      };

      # Keyboard configuration
      input = {
        "*" = {
          xkb_layout = "us";
          repeat_delay = "200";
          repeat_rate = "50";
        };
        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "disabled";
        };
      };

      # General settings
      gaps = {
        inner = 4;
        outer = 8;
      };

      border = 2;
      focus.wrapping = "yes";
      focus.mouseWarping = "output";

      # Colors with retroism theme
      colors = {
        background = semanticColors.background.primary;
        focused = {
          background = semanticColors.accent.primary;
          border = semanticColors.accent.primary;
          childBorder = semanticColors.accent.primary;
          indicator = semanticColors.foreground.primary;
          text = semanticColors.background.primary;
        };
        focusedInactive = {
          background = semanticColors.background.secondary;
          border = semanticColors.foreground.muted;
          childBorder = semanticColors.background.secondary;
          indicator = semanticColors.background.secondary;
          text = semanticColors.foreground.primary;
        };
        unfocused = {
          background = semanticColors.background.secondary;
          border = semanticColors.background.tertiary;
          childBorder = semanticColors.background.secondary;
          indicator = semanticColors.background.secondary;
          text = semanticColors.foreground.muted;
        };
        urgent = {
          background = semanticColors.semantic.error;
          border = semanticColors.semantic.error;
          childBorder = semanticColors.semantic.error;
          indicator = semanticColors.semantic.error;
          text = semanticColors.foreground.primary;
        };
      };

      # Workspaces
      workspaceAutoBackAndForth = true;
      workspaceLayout = "default";

      # Key bindings - Super key
      modifier = "Mod4";

      keybindings =
        let
          mod = "Mod4";
        in
        {
          # Focus movement (hjkl)
          "${mod}+h" = "focus left";
          "${mod}+j" = "focus down";
          "${mod}+k" = "focus up";
          "${mod}+l" = "focus right";

          # Move windows (Super+Shift+hjkl)
          "${mod}+Shift+h" = "move left";
          "${mod}+Shift+j" = "move down";
          "${mod}+Shift+k" = "move up";
          "${mod}+Shift+l" = "move right";

          # Window management
          "${mod}+q" = "kill"; # Close window
          "${mod}+w" = "layout tabbed"; # Tab layout
          "${mod}+space" = "floating toggle"; # Float/tile toggle
          "${mod}+f" = "fullscreen toggle"; # Fullscreen
          "${mod}+m" = "layout toggle split"; # Toggle split layout (master)

          # Workspaces (Super+1-9)
          "${mod}+1" = "workspace number 1";
          "${mod}+2" = "workspace number 2";
          "${mod}+3" = "workspace number 3";
          "${mod}+4" = "workspace number 4";
          "${mod}+5" = "workspace number 5";
          "${mod}+6" = "workspace number 6";
          "${mod}+7" = "workspace number 7";
          "${mod}+8" = "workspace number 8";
          "${mod}+9" = "workspace number 9";

          # Move to workspace (Super+Shift+1-9)
          "${mod}+Shift+1" = "move container to workspace number 1";
          "${mod}+Shift+2" = "move container to workspace number 2";
          "${mod}+Shift+3" = "move container to workspace number 3";
          "${mod}+Shift+4" = "move container to workspace number 4";
          "${mod}+Shift+5" = "move container to workspace number 5";
          "${mod}+Shift+6" = "move container to workspace number 6";
          "${mod}+Shift+7" = "move container to workspace number 7";
          "${mod}+Shift+8" = "move container to workspace number 8";
          "${mod}+Shift+9" = "move container to workspace number 9";

          # Cycle workspaces (Super+Tab/Super+Shift+Tab)
          "${mod}+Tab" = "workspace next";
          "${mod}+Shift+Tab" = "workspace prev";

          # Applications
          "${mod}+t" = "exec wezterm"; # Terminal
          "${mod}+n" = "exec nemo"; # File manager (n for nemo)
          "${mod}+d" = "exec wofi --show=drun"; # Application launcher

          # System
          "${mod}+Escape" = "exit"; # Exit sway
          "${mod}+r" = "mode resize"; # Resize mode
        };

      modes = {
        resize = {
          "h" = "resize shrink width 10 px";
          "j" = "resize grow height 10 px";
          "k" = "resize shrink height 10 px";
          "l" = "resize grow width 10 px";
          "Escape" = "mode default";
          "Return" = "mode default";
        };
      };

      # Bar configuration
      bars = [
        {
          position = "top";
          statusCommand = "waybar";
          colors = {
            background = semanticColors.background.primary;
            statusline = semanticColors.foreground.primary;
            focusedBackground = semanticColors.accent.primary;
            focusedStatusline = semanticColors.background.primary;
            focusedBorder = semanticColors.accent.primary;
            focusedWorkspace = {
              background = semanticColors.accent.primary;
              border = semanticColors.accent.primary;
              text = semanticColors.background.primary;
            };
            activeWorkspace = {
              background = semanticColors.background.secondary;
              border = semanticColors.foreground.primary;
              text = semanticColors.foreground.primary;
            };
            inactiveWorkspace = {
              background = semanticColors.background.secondary;
              border = semanticColors.background.tertiary;
              text = semanticColors.foreground.muted;
            };
            urgentWorkspace = {
              background = semanticColors.semantic.error;
              border = semanticColors.semantic.error;
              text = semanticColors.foreground.primary;
            };
          };
        }
      ];

      # Window rules
      floating = [
        { class = "pavucontrol"; }
        { class = "nm-connection-editor"; }
        { class = "blueman-manager"; }
        { class = "file-roller"; }
        { class = "1Password"; }
      ];

      # Floating window settings
      floatingModifier = "Mod4";
      floating.border = 2;

      # Startup commands
      startup = [
        { command = "swaybg -i ~/.config/sway/background.png"; always = true; }
        { command = "waybar"; always = true; }
      ];
    };

    extraConfig = ''
      # Default font
      font ${values.theme.font.monospace} 10
    '';
  };
}
