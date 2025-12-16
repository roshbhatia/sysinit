{
  lib,
  values,
  ...
}:

let
  themes = import ../../shared/lib/theme { inherit lib; };
  theme = themes.getTheme values.theme.colorscheme;
  niriTheme = themes.adapters.niri.createNiriTheme theme values.theme;
  colors = niriTheme.niriColors;
in
{
  programs.niri.settings = {
    input = {
      keyboard.xkb.layout = "us";

      touchpad = {
        natural-scroll = false;
        tap = true;
      };

      mouse = {
        accel-speed = 0.0;
      };
    };

    layout = {
      gaps = 12;

      border = {
        width = 2;
        active.color = colors.activeBorder;
        inactive.color = colors.inactiveBorder;
      };

      focus-ring = {
        width = 2;
        active.color = colors.accent;
        inactive.color = colors.inactiveBorder;
      };

      preset-column-widths = [
        { proportion = 1.0 / 3.0; }
        { proportion = 1.0 / 2.0; }
        { proportion = 2.0 / 3.0; }
      ];

      default-column-width = {
        proportion = 1.0 / 2.0;
      };
    };

    spawn-at-startup = [
      { command = [ "waybar" ]; }
    ];

    binds = {
      # Launchers (similar to macOS Spotlight/Alfred)
      # Super+Space opens the app picker (like Raycast/Spotlight)
      "Mod+Space".action.spawn = [
        "wofi"
        "--show=drun"
      ];

      # Focus movement - matches Aerospace alt-h/j/k/l
      # Note: Mod = Super on Linux, matching the "alt" feel from macOS
      "Mod+H".action.focus-column-left = { };
      "Mod+J".action.focus-window-down = { };
      "Mod+K".action.focus-window-up = { };
      "Mod+L".action.focus-column-right = { };

      # Move windows - matches Aerospace alt-cmd-h/j/k/l
      "Mod+Shift+H".action.move-column-left = { };
      "Mod+Shift+J".action.move-window-down = { };
      "Mod+Shift+K".action.move-window-up = { };
      "Mod+Shift+L".action.move-column-right = { };

      # Resize - matches Aerospace alt-minus/equal and alt-shift-minus/equal
      "Mod+Minus".action.set-column-width = "-10%";
      "Mod+Equal".action.set-column-width = "+10%";
      "Mod+Shift+Minus".action.set-column-width = "-25%";
      "Mod+Shift+Equal".action.set-column-width = "+25%";

      # Workspaces - Aerospace uses 1, 2, C, E, M
      # Map to: 1=dev, 2=secondary, 3=comms(C), 4=email(E), 5=media(M)
      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;

      # Move to workspace - matches Aerospace alt-shift-1/2/C/E/M
      "Mod+Shift+1".action.move-column-to-workspace = 1;
      "Mod+Shift+2".action.move-column-to-workspace = 2;
      "Mod+Shift+3".action.move-column-to-workspace = 3;
      "Mod+Shift+4".action.move-column-to-workspace = 4;
      "Mod+Shift+5".action.move-column-to-workspace = 5;
      "Mod+Shift+6".action.move-column-to-workspace = 6;
      "Mod+Shift+7".action.move-column-to-workspace = 7;
      "Mod+Shift+8".action.move-column-to-workspace = 8;
      "Mod+Shift+9".action.move-column-to-workspace = 9;

      # Workspace cycling - matches Aerospace alt-tab/alt-shift-tab
      "Mod+Tab".action.focus-workspace-down = { };
      "Mod+Shift+Tab".action.focus-workspace-up = { };

      # Fullscreen/Maximize - matches Aerospace alt-f
      "Mod+F".action.maximize-column = { };
      "Mod+Shift+F".action.fullscreen-window = { };

      # Layout switching - matches Aerospace alt-t (tiles) and alt-a (accordion)
      "Mod+Slash".action.switch-preset-column-width = { };
      "Mod+T".action.consume-or-expel-window-left = { };
      "Mod+A".action.center-column = { };

      # Close window
      "Mod+Q".action.close-window = { };

      # Config reload - matches Aerospace alt-esc
      "Mod+Escape".action.quit = {
        skip-confirmation = true;
      };
      "Mod+Shift+Escape".action.quit = { };

      # Screenshot
      "Mod+S".action.screenshot = { };
      "Mod+Shift+S".action.screenshot-screen = { };
      "Mod+Ctrl+S".action.screenshot-window = { };

      # Additional useful bindings
      "Mod+Comma".action.consume-window-into-column = { };
      "Mod+Period".action.expel-window-from-column = { };
    };

    # Window rules - map apps to workspaces like Aerospace on-window-detected
    window-rules = [
      # Communications (workspace 3) - like Aerospace "C" workspace
      {
        matches = [ { app-id = "^org\\.ferdium\\."; } ];
        open-on-workspace = "3";
      }
      {
        matches = [ { app-id = "^Slack$"; } ];
        open-on-workspace = "3";
      }
      {
        matches = [ { app-id = "^discord$"; } ];
        open-on-workspace = "3";
      }

      # Email (workspace 4) - like Aerospace "E" workspace
      {
        matches = [ { app-id = "^thunderbird"; } ];
        open-on-workspace = "4";
      }
      {
        matches = [ { app-id = "^evolution$"; } ];
        open-on-workspace = "4";
      }

      # Media (workspace 5) - like Aerospace "M" workspace
      {
        matches = [ { app-id = "^spotify$"; } ];
        open-on-workspace = "5";
      }
      {
        matches = [ { app-id = "^Audacious$"; } ];
        open-on-workspace = "5";
      }

      # Floating windows - like Aerospace floating layout rules
      {
        matches = [ { app-id = "^1[Pp]assword$"; } ];
        open-floating = true;
      }
      {
        matches = [ { app-id = "^pavucontrol$"; } ];
        open-floating = true;
      }
      {
        matches = [ { app-id = "^nm-connection-editor$"; } ];
        open-floating = true;
      }
      {
        matches = [ { app-id = "^blueman-manager$"; } ];
        open-floating = true;
      }
      {
        matches = [ { app-id = "^file-roller$"; } ];
        open-floating = true;
      }
    ];
  };
}
