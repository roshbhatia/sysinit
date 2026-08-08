{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.aerospork;

  format = pkgs.formats.toml { };
  configFile = format.generate "aerospork.toml" cfg.settings;

  # Both workspace hooks feed the same sketchybar item, so the trigger is written
  # once.
  #
  # The focused name is queried back out of the CLI rather than read from
  # $AEROSPORK_FOCUSED_WORKSPACE. That variable is populated only by
  # `onWorkspaceChanged`, which serves the deprecated exec-on-workspace-change key;
  # an on-focused-workspace-changed callback runs with exec.env-variables alone, so
  # the variable expands empty and sketchybar highlights nothing.
  notifySketchybar = "${pkgs.sketchybar}/bin/sketchybar --trigger aerospace_workspace_change FOCUSED=$(${pkgs.aerospork}/bin/aerospork list-workspaces --focused)";
in
{
  # nix-darwin ships services.aerospace, but it hardcodes the AeroSpace.app path
  # into the launchd command, so it cannot point at a fork. Reimplemented here
  # rather than faking that path inside aerospork's notarized bundle, which would
  # break the signature seal. See overlays/aerospork.nix.
  options.services.aerospork.settings = lib.mkOption {
    type = format.type;
    default = { };
    description = ''
      aerospork configuration, rendered to TOML and passed as --config-path.
      Read by ./keybindings.nix, which asserts that no binding here collides with
      an enabled symbolic hotkey or a reserved chord.
    '';
  };

  config.environment.systemPackages = [ pkgs.aerospork ];

  config.launchd.user.agents.aerospork = {
    command = "${pkgs.aerospork}/Applications/AeroSpork.app/Contents/MacOS/AeroSpork --config-path ${configFile}";
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
    };
  };

  config.services.aerospork.settings = {
    # launchd owns startup; aerospork's own SMAppService login item would race it.
    start-at-login = false;

    # No persistent-workspaces key in this fork, and no way to emulate it:
    # garbageCollectUnusedWorkspaces drops every empty invisible workspace, and
    # preservedWorkspaceNames only keeps a stub from stealing a bound name. So
    # `list-workspaces --all` reports the occupied ones alone, and the sketchybar
    # chips are declared from these bindings instead of discovered at bar startup.

    # No `/bin/bash -c` here: exec-and-forget already runs its argument through
    # /bin/bash -c, and the old config's second wrapper ate every argument after
    # the binary, so sketchybar was triggered with no FOCUSED at all.
    on-focused-workspace-changed = [
      "exec-and-forget ${notifySketchybar}"
    ];

    on-focus-changed = [
      "exec-and-forget ${notifySketchybar}"
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
          62
        ];
        bottom = [
          { monitor."LG HDR 4K" = 200; }
          14
        ];
      };
    };

    on-window-detected = [
      {
        "if" = {
          app-id = "com.hnc.Discord";
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
      {
        "if" = {
          app-id = "com.apple.calculator";
        };
        run = [ "layout floating" ];
      }
      {
        "if" = {
          app-id = "com.apple.ActivityMonitor";
        };
        run = [ "layout floating" ];
      }
      {
        "if" = {
          app-id = "com.apple.DiskUtility";
        };
        run = [ "layout floating" ];
      }
      {
        "if" = {
          app-id = "com.apple.FontBook";
        };
        run = [ "layout floating" ];
      }
      {
        "if" = {
          app-id = "com.apple.Console";
        };
        run = [ "layout floating" ];
      }
      {
        "if" = {
          app-id = "com.apple.Stickies";
        };
        run = [ "layout floating" ];
      }
      {
        "if" = {
          app-id = "com.apple.archiveutility";
        };
        run = [ "layout floating" ];
      }
      {
        "if" = {
          app-id = "com.apple.ScreenSharing";
        };
        run = [ "layout floating" ];
      }
      {
        "if" = {
          app-id = "com.apple.Image_Capture";
        };
        run = [ "layout floating" ];
      }
      {
        "if" = {
          app-id = "com.apple.audio.AudioMIDISetup";
        };
        run = [ "layout floating" ];
      }
      {
        "if" = {
          app-id = "com.okta.mobile";
        };
        run = [ "layout floating" ];
      }
      {
        "if" = {
          app-id = "org.hammerspoon.Hammerspoon";
        };
        run = [ "layout floating" ];
      }
    ];

    mode = {
      main.binding = {
        alt-enter = "exec-and-forget ${pkgs.wezterm}/bin/wezterm cli spawn --new-window";

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

        alt-r = [
          "exec-and-forget ${pkgs.sketchybar}/bin/sketchybar --trigger aerospace_mode_changed MODE=RESIZE"
          "mode resize"
        ];

        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-c = "workspace C";
        alt-m = "workspace M";
        alt-shift-1 = "move-node-to-workspace 1 --focus-follows-window";
        alt-shift-2 = "move-node-to-workspace 2 --focus-follows-window";
        alt-shift-c = "move-node-to-workspace C --focus-follows-window";
        alt-shift-m = "move-node-to-workspace M --focus-follows-window";

        alt-tab = "workspace --wrap-around next";
        alt-shift-tab = "workspace --wrap-around prev";
        alt-p = "workspace-back-and-forth";

        alt-f = "fullscreen";
        alt-shift-f = "fullscreen --no-outer-gaps";
      };

      locked.binding = {
        alt-esc = [
          "exec-and-forget ${pkgs.sketchybar}/bin/sketchybar --trigger aerospace_mode_changed MODE=MAIN"
          "mode main"
        ];
      };

      resize.binding = {
        alt-esc = [
          "exec-and-forget ${pkgs.sketchybar}/bin/sketchybar --trigger aerospace_mode_changed MODE=MAIN"
          "mode main"
        ];

        alt-h = "resize smart -72";
        alt-j = "resize smart -72";
        alt-k = "resize smart +72";
        alt-l = "resize smart +72";
      };

      move.binding = {
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
