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
          horizontal = 16;
          vertical = 16;
        };
        outer = {
          left = [
            { monitor."LG HDR 4K" = 400; }
            { monitor."DELL U3824DW" = 128; }
            16
          ];
          right = [
            { monitor."LG HDR 4K" = 400; }
            { monitor."DELL U3824DW" = 128; }
            16
          ];
          top = [
            { monitor."LG HDR 4K" = 200; }
            48
          ];
          bottom = [
            { monitor."LG HDR 4K" = 200; }
            8
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

      mode.main.binding = {
        alt-enter = ''
          exec-and-forget osascript -e '
            tell application "Wezterm"
              activate
            end tell'
        '';

        alt-t = "layout tiles horizontal vertical";
        alt-a = "layout accordion horizontal vertical";

        alt-x = [
          "exec-and-forget ${pkgs.sketchybar}/bin/sketchybar --trigger aerospace_mode_changed MODE=MOVE"
          "mode move"
        ];

        alt-g = [
          "exec-and-forget ${pkgs.sketchybar}/bin/sketchybar --trigger aerospace_mode_changed MODE=LOCKED"
          "mode locked"
        ];

        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        alt-shift-j = "resize smart -72";
        alt-shift-k = "resize smart +72";

        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-c = "workspace C";
        alt-e = "workspace E";
        alt-m = "workspace M";
        alt-shift-1 = "move-node-to-workspace 1 --focus-follows-window";
        alt-shift-2 = "move-node-to-workspace 2 --focus-follows-window";
        alt-shift-c = "move-node-to-workspace C --focus-follows-window";
        alt-shift-e = "move-node-to-workspace E --focus-follows-window";
        alt-shift-m = "move-node-to-workspace M --focus-follows-window";

        alt-tab = "workspace --wrap-around next";
        alt-shift-tab = "workspace --wrap-around prev";
        alt-p = "workspace-back-and-forth";

        alt-f = "fullscreen";
        alt-esc = "mode main";
      };

      mode.locked.binding = {
        alt-esc = [
          "exec-and-forget ${pkgs.sketchybar}/bin/sketchybar --trigger aerospace_mode_changed MODE=MAIN"
          "mode main"
        ];
      };

      mode.move.binding = {
        alt-esc = [
          "exec-and-forget ${pkgs.sketchybar}/bin/sketchybar --trigger aerospace_mode_changed MODE=MAIN"
          "mode main"
        ];

        alt-h = "move left";
        alt-j = "move down";
        alt-k = "move up";
        alt-l = "move right";
      };
    };
  };
}
