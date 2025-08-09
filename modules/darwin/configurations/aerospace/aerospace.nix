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
          run = "move-node-to-workspace S";
        }
        # Floating windows for specific apps
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
            # Window movement
            alt-shift-h = "move left";
            alt-shift-j = "move down";
            alt-shift-k = "move up";
            alt-shift-l = "move right";
            # Navigation
            alt-h = "focus left";
            alt-j = "focus down";
            alt-k = "focus up";
            alt-l = "focus right";
            # Base resize commands
            alt-minus = "resize smart -70";
            alt-equal = "resize smart +70";
            alt-shift-minus = "resize smart -210";
            alt-shift-equal = "resize smart +210";
            # Workspace management
            alt-1 = "workspace 1";
            alt-2 = "workspace 2";
            alt-3 = "workspace 3";
            alt-4 = "workspace 4";
            alt-c = "workspace C";
            alt-m = "workspace M";
            alt-s = "workspace S";
            alt-e = "workspace E";
            alt-shift-1 = "move-node-to-workspace 1 --focus-follows-window";
            alt-shift-2 = "move-node-to-workspace 2 --focus-follows-window";
            alt-shift-3 = "move-node-to-workspace 3 --focus-follows-window";
            alt-shift-4 = "move-node-to-workspace 4 --focus-follows-window";
            alt-shift-c = "move-node-to-workspace C --focus-follows-window";
            alt-shift-e = "move-node-to-workspace E --focus-follows-window";
            alt-shift-m = "move-node-to-workspace M --focus-follows-window";
            alt-shift-s = "move-node-to-workspace S --focus-follows-window";
            alt-shift-x = "move-node-to-workspace X --focus-follows-window";
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
