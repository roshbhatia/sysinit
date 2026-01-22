# Darwin aerospace: tiling window manager
{ pkgs, ... }:

{
  services.aerospace = {
    enable = true;

    settings = {
      exec-on-workspace-change = [
        "/bin/bash"
        "-c"
        "${pkgs.sketchybar}/bin/sketchybar --trigger aerospace_workspace_change FOCUSED=$AEROSPACE_FOCUSED_WORKSPACE"
      ];

      on-focus-changed = [
        "exec-and-forget /bin/bash -c ${pkgs.sketchybar}/bin/sketchybar --trigger aerospace_workspace_change FOCUSED=$AEROSPACE_FOCUSED_WORKSPACE"
      ];

      gaps = {
        inner = {
          horizontal = 12;
          vertical = 12;
        };
        outer = {
          left = [
            { monitor."LG HDR 4K" = 400; }
            { monitor."DELL U3824DW" = 326; }
            16
          ];
          right = [
            { monitor."LG HDR 4K" = 400; }
            { monitor."DELL U3824DW" = 326; }
            16
          ];
          top = [
            { monitor."LG HDR 4K" = 200; }
            { monitor."DELL U3824DW" = 56; }
            56
          ];
          bottom = [
            { monitor."LG HDR 4K" = 200; }
            { monitor."DELL U3824DW" = 20; }
            20
          ];
        };
      };

      on-window-detected = [
        {
          "if" = {
            app-id = "org.ferdium.ferdium-app";
          };
          run = "move-node-to-workspace C";
        }
        {
          "if" = {
            app-id = "com.facebook.archon.developerID";
          };
          run = "move-node-to-workspace C";
        }
        {
          "if" = {
            app-id = "com.microsoft.Outlook";
          };
          run = "move-node-to-workspace C";
        }
        {
          "if" = {
            app-id = "com.apple.iBooksX";
          };
          run = "move-node-to-workspace M";
        }
        {
          "if" = {
            app-id = "com.apple.Music";
          };
          run = "move-node-to-workspace M";
        }
        {
          "if" = {
            app-id = "com.apple.Podcasts";
          };
          run = "move-node-to-workspace M";
        }
        {
          "if" = {
            app-name-regex-substring = "Audible";
            window-title-regex-substring = "Audible Cloud Player";
          };
          run = "move-node-to-workspace M";
        }
        {
          "if" = {
            app-id = "com.tinyspeck.slackmacgap";
          };
          run = "move-node-to-workspace C";
        }
        {
          "if" = {
            app-id = "com.apple.systempreferences";
          };
          run = [ "layout floating" ];
        }
        {
          "if" = {
            app-id = "com.1password.1password";
          };
          run = [ "layout floating" ];
        }
        {
          "if" = {
            app-id = "com.apple.keychainaccess";
          };
          run = [ "layout floating" ];
        }
        {
          "if" = {
            app-id = "com.apple.finder";
          };
          run = [ "layout floating" ];
        }
        {
          "if" = {
            app-id = "com.apple.MobileSMS";
          };
          run = [ "layout floating" ];
        }
        {
          "if" = {
            app-id = "com.apple.FaceTime";
          };
          run = [ "layout floating" ];
        }
      ];

      # i3-style keybindings (alt = $mod)
      mode.main.binding = {
        # Launch terminal (i3: $mod+Return)
        alt-enter = "exec-and-forget wezterm start --always-new-process";

        # Kill focused window (i3: $mod+Shift+q)
        alt-shift-q = "close";

        # Focus movement (i3: $mod+hjkl)
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        # Move focused window (i3: $mod+Shift+hjkl)
        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        # Join with adjacent window (i3: $mod+v/b for split, aerospace recommends join-with)
        # join-with creates a container with the focused window and the nearest window in that direction
        alt-v = "join-with down";
        alt-b = "join-with right";

        # Layout toggles (i3: $mod+e for split, $mod+s for stacking, $mod+w for tabbed)
        alt-e = "layout tiles horizontal vertical";
        alt-s = "layout accordion horizontal";
        alt-w = "layout accordion vertical";

        # Fullscreen (i3: $mod+f)
        alt-f = "fullscreen";

        # Floating toggle (i3: $mod+Shift+space)
        alt-shift-space = "layout floating tiling";

        # Toggle focus between floating and tiling (i3: $mod+space) - not available in aerospace
        # Focus back and forth as alternative
        alt-space = "focus-back-and-forth";

        # Flatten workspace tree (closest to i3's parent focus behavior)
        alt-a = "flatten-workspace-tree";

        # Workspaces (i3: $mod+number)
        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-c = "workspace C";
        alt-m = "workspace M";

        # Move to workspace (i3: $mod+Shift+number)
        alt-shift-1 = "move-node-to-workspace 1 --focus-follows-window";
        alt-shift-2 = "move-node-to-workspace 2 --focus-follows-window";
        alt-shift-3 = "move-node-to-workspace 3 --focus-follows-window";
        alt-shift-4 = "move-node-to-workspace 4 --focus-follows-window";
        alt-shift-5 = "move-node-to-workspace 5 --focus-follows-window";
        alt-shift-c = "move-node-to-workspace C --focus-follows-window";
        alt-shift-m = "move-node-to-workspace M --focus-follows-window";

        # Workspace navigation
        alt-tab = "workspace --wrap-around next";
        alt-shift-tab = "workspace --wrap-around prev";
        alt-p = "workspace-back-and-forth";

        # Enter resize mode (i3: $mod+r)
        alt-r = "mode resize";

        # Reload config (i3: $mod+Shift+c for reload, $mod+Shift+r for restart)
        alt-shift-r = [
          "reload-config"
          "mode main"
        ];
      };

      # Resize mode (i3: resize mode with hjkl)
      mode.resize.binding = {
        h = "resize width -72";
        j = "resize height +72";
        k = "resize height -72";
        l = "resize width +72";
        # Fine-grained resize with shift
        shift-h = "resize width -24";
        shift-j = "resize height +24";
        shift-k = "resize height -24";
        shift-l = "resize width +24";
        # Exit resize mode (i3: Return or Escape)
        enter = "mode main";
        esc = "mode main";
      };
    };
  };
}
