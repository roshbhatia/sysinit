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
      output = {
        "*" = {
          bg = "#${lib.strings.removePrefix "#" semanticColors.background.primary} solid_color";
        };
      };

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

      gaps = {
        inner = 4;
        outer = 8;
      };

      focus.wrapping = "yes";
      focus.mouseWarping = "output";

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
          mod = "Mod4"; # Super key
          alt = "Mod1"; # Alt key
        in
        {
          # Launcher (Spotlight-style)
          "${mod}+space" = "exec wofi --show=drun";

          # Application launchers
          "${mod}+t" = "exec wezterm";
          "${mod}+n" = "exec nemo";
          "${mod}+Return" = "exec wezterm";

          # Window management
          "${mod}+w" = "kill";
          "${mod}+f" = "fullscreen toggle";
          "${mod}+h" = "move scratchpad";
          "${mod}+m" = "move scratchpad";

          # Focus movement (hjkl) - Alt+hjkl like aerospace
          "${alt}+h" = "focus left";
          "${alt}+j" = "focus down";
          "${alt}+k" = "focus up";
          "${alt}+l" = "focus right";

          # Move windows (Alt+Cmd+hjkl like aerospace)
          "${alt}+${mod}+h" = "move left";
          "${alt}+${mod}+j" = "move down";
          "${alt}+${mod}+k" = "move up";
          "${alt}+${mod}+l" = "move right";

          # Resize in resize mode
          "${mod}+r" = "mode resize";

          # Workspaces - Alt+number/letter (like aerospace)
          # General workspaces
          "${alt}+1" = "workspace number 1";
          "${alt}+2" = "workspace number 2";
          # Chat workspace
          "${alt}+c" = "workspace C";
          # Steam workspace
          "${alt}+s" = "workspace S";

          # Move to workspace (Alt+Shift+number/letter)
          "${alt}+Shift+1" = "move container to workspace number 1; workspace number 1";
          "${alt}+Shift+2" = "move container to workspace number 2; workspace number 2";
          "${alt}+Shift+c" = "move container to workspace C; workspace C";
          "${alt}+Shift+s" = "move container to workspace S; workspace S";

          # Cycle workspaces
          "${alt}+Tab" = "workspace next";
          "${alt}+Shift+Tab" = "workspace prev";

          # System
          "${mod}+Escape" = "exit";
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

      # Window rules
      floating = {
        criteria = [
          { class = "pavucontrol"; }
          { class = "nm-connection-editor"; }
          { class = "blueman-manager"; }
          { class = "file-roller"; }
          { class = "1Password"; }
        ];
      };

      # Startup commands
      startup = [
        {
          command = "swaybg -i ~/.background-image || swaybg -c ${semanticColors.background.primary}";
          always = true;
        }
        {
          command = "waybar";
          always = true;
        }
        {
          command = "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP";
          always = true;
        }
      ];
    };

    extraConfig = ''
      font ${values.theme.font.monospace} 10
    '';
  };
}
