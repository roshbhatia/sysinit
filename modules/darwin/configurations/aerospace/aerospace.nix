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
        {
          "if" = {
            app-id = "com.electron.ollama";
          };
          run = "move-node-to-workspace O";
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

        {
          "if" = {
            app-id = "com.mitchellh.ghostty";
          };
          run = [ "layout tiling" ];
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

            alt-1 = "workspace 1";
            alt-2 = "workspace 2";
            alt-3 = "workspace 3";
            alt-c = "workspace C";
            alt-m = "workspace M";
            alt-s = "workspace S";
            alt-e = "workspace E";
            alt-o = "workspace O";

            alt-tab = "workspace --wrap-around next";
            alt-shift-tab = "workspace --wrap-around prev";
            alt-space = "workspace-back-and-forth";

            alt-shift-1 = "move-node-to-workspace 1 --focus-follows-window";
            alt-shift-2 = "move-node-to-workspace 2 --focus-follows-window";
            alt-shift-3 = "move-node-to-workspace 3 --focus-follows-window";
            alt-shift-c = "move-node-to-workspace C --focus-follows-window";
            alt-shift-e = "move-node-to-workspace E --focus-follows-window";
            alt-shift-m = "move-node-to-workspace M --focus-follows-window";
            alt-shift-s = "move-node-to-workspace S --focus-follows-window";
            alt-shift-o = "move-node-to-workspace O --focus-follows-window";

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
