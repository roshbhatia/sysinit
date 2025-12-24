{
  pkgs,
  ...
}:
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
            { monitor."LG HDR 4K" = 480; }
            { monitor."DELL U3824DW" = 326; }
            16
          ];
          right = [
            { monitor."LG HDR 4K" = 480; }
            { monitor."DELL U3824DW" = 326; }
            16
          ];
          top = [
            { monitor."LG HDR 4K" = 200; }
            { monitor."DELL U3824DW" = 56; }
            60
          ];
          bottom = [
            { monitor."LG HDR 4K" = 200; }
            { monitor."DELL U3824DW" = 20; }
            24
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
          run = "move-node-to-workspace E";
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
      mode = {
        main = {
          binding = {
            alt-enter = ''
              exec-and-forget osascript -e '
                            tell application "WezTerm"
                              activate
                            end tell'
            '';

            alt-t = "layout tiles horizontal vertical";
            alt-a = "layout accordion horizontal vertical";

            alt-h = "focus left";
            alt-j = "focus down";
            alt-k = "focus up";
            alt-l = "focus right";

            alt-cmd-h = "move left";
            alt-cmd-j = "move down";
            alt-cmd-k = "move up";
            alt-cmd-l = "move right";

            alt-shift-j = "resize smart -72";
            alt-shift-k = "resize smart +72";

            alt-1 = "workspace 1";
            alt-2 = "workspace 2";
            alt-c = "workspace C";
            alt-e = "workspace E";
            alt-m = "workspace M";

            alt-tab = "workspace --wrap-around next";
            alt-shift-tab = "workspace --wrap-around prev";
            alt-space = "workspace-back-and-forth";

            alt-shift-1 = "move-node-to-workspace 1 --focus-follows-window";
            alt-shift-2 = "move-node-to-workspace 2 --focus-follows-window";
            alt-shift-c = "move-node-to-workspace C --focus-follows-window";
            alt-shift-e = "move-node-to-workspace E --focus-follows-window";
            alt-shift-m = "move-node-to-workspace M --focus-follows-window";

            alt-f = "fullscreen";

            alt-esc = [
              "reload-config"
              "mode main"
            ];
          };
        };
      };
    };
  };
}
