{
  pkgs,
  ...
}:
{
  services.aerospace = {
    enable = true;
    package = pkgs.aerospace;

    settings = {
      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;
      accordion-padding = 30;
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";
      on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];
      automatically-unhide-macos-hidden-apps = false;

      key-mapping = {
        preset = "qwerty";
      };

      gaps = {
        inner = {
          horizontal = 8;
          vertical = 8;
        };
        outer = {
          right = 16;
          left = 16;
          bottom = 24;
          top = 24;
        };
      };

      on-window-detected = [
        {
          "if" = {
            app-id = "org.ferdium.ferdium-app";
          };
          run = "move-node-to-workspace 7";
        }
        {
          "if" = {
            app-id = "com.facebook.archon.developerID";
          };
          run = "move-node-to-workspace 7";
        }
        {
          "if" = {
            app-id = "com.microsoft.Outlook";
          };
          run = "move-node-to-workspace 5";
        }
        {
          "if" = {
            app-id = "com.apple.iBooksX";
          };
          run = "move-node-to-workspace 6";
        }
        {
          "if" = {
            app-id = "com.apple.Music";
          };
          run = "move-node-to-workspace 6";
        }
        {
          "if" = {
            app-id = "com.apple.Podcasts";
          };
          run = "move-node-to-workspace 6";
        }
        {
          "if" = {
            app-name-regex-substring = "Audible";
            window-title-regex-substring = "Audible Cloud Player";
          };
          run = "move-node-to-workspace 6";
        }
        {
          "if" = {
            app-id = "com.tinyspeck.slackmacgap";
          };
          run = "move-node-to-workspace 4";
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
            alt-slash = "layout tiles horizontal vertical";
            alt-comma = "layout accordion horizontal vertical";

            alt-h = "focus left";
            alt-j = "focus down";
            alt-k = "focus up";
            alt-l = "focus right";

            alt-cmd-h = "move left";
            alt-cmd-j = "move down";
            alt-cmd-k = "move up";
            alt-cmd-l = "move right";

            alt-minus = "resize smart -70";
            alt-equal = "resize smart +70";
            alt-shift-minus = "resize smart -210";
            alt-shift-equal = "resize smart +210";

            # Workspace management
            alt-1 = "workspace 1";
            alt-2 = "workspace 2";
            alt-3 = "workspace 3";
            alt-4 = "workspace 4";
            alt-5 = "workspace 5";
            alt-6 = "workspace 6";
            alt-7 = "workspace 7";
            alt-8 = "workspace 8";

            alt-tab = "workspace --wrap-around next";
            alt-shift-tab = "workspace --wrap-around prev";
            alt-space = "workspace-back-and-forth";

            alt-shift-1 = "move-node-to-workspace 1 --focus-follows-window";
            alt-shift-2 = "move-node-to-workspace 2 --focus-follows-window";
            alt-shift-3 = "move-node-to-workspace 3 --focus-follows-window";
            alt-shift-4 = "move-node-to-workspace 4 --focus-follows-window";
            alt-shift-5 = "move-node-to-workspace 5 --focus-follows-window";
            alt-shift-6 = "move-node-to-workspace 6 --focus-follows-window";
            alt-shift-7 = "move-node-to-workspace 7 --focus-follows-window";
            alt-shift-8 = "move-node-to-workspace 8 --focus-follows-window";

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
