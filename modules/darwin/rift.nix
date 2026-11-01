{
  config,
  lib,
  pkgs,
  ...
}:

let
  format = pkgs.formats.toml { };
  home = config.home-manager.users.${config.sysinit.user.username};
  user = config.sysinit.user.username;
  weztermApp = "${home.home.homeDirectory}/${home.targets.darwin.copyApps.directory}/WezTerm.app";
  sketchybar = "${pkgs.sketchybar}/bin/sketchybar";
  riftCli = "${pkgs.rift}/bin/rift-cli";
  notifyScript = pkgs.writeShellScript "rift-sketchybar-event" ''
    set -euo pipefail
    case "''${RIFT_EVENT_TYPE:-}" in
      workspace_changed)
        exec ${sketchybar} --trigger rift_workspace_changed FOCUSED="''${RIFT_WORKSPACE_NAME:-}"
        ;;
      binding_mode_changed)
        mode="''${RIFT_BINDING_MODE:-default}"
        if [ "$mode" = default ]; then
          mode=MAIN
        else
          mode="''${mode^^}"
        fi
        exec ${sketchybar} --trigger rift_mode_changed MODE="$mode"
        ;;
    esac
  '';
  floatingApps = [
    "com.apple.systempreferences"
    "com.1password.1password"
    "com.apple.keychainaccess"
    "com.apple.finder"
    "com.apple.MobileSMS"
    "com.apple.FaceTime"
    "com.apple.calculator"
    "com.apple.ActivityMonitor"
    "com.apple.DiskUtility"
    "com.apple.FontBook"
    "com.apple.Console"
    "com.apple.Stickies"
    "com.apple.archiveutility"
    "com.apple.ScreenSharing"
    "com.apple.Image_Capture"
    "com.apple.audio.AudioMIDISetup"
    "com.okta.mobile"
    "org.hammerspoon.Hammerspoon"
  ];
  exitMode = [ { binding_mode = "default"; } ];
  commands = {
    "Alt + Enter" = {
      exec = [
        "${pkgs.sysinit-utils}/bin/wezspawn"
        "--wezterm"
        "${pkgs.wezterm}/bin/wezterm"
        "--gui-app"
        weztermApp
      ];
    };
    "Alt + T" = [
      {
        set_workspace_layout = {
          mode = "traditional";
        };
      }
      "toggle_orientation"
    ];
    "Alt + E" = [
      {
        set_workspace_layout = {
          mode = "traditional";
        };
      }
      "toggle_orientation"
    ];
    "Alt + A" = [
      {
        set_workspace_layout = {
          mode = "stack";
        };
      }
      "toggle_orientation"
    ];
    "Alt + S" = {
      set_workspace_layout = {
        mode = "stack";
      };
    };
    "Alt + W" = [
      {
        set_workspace_layout = {
          mode = "stack";
        };
      }
      "toggle_orientation"
    ];
    "Alt + Shift + Space" = "toggle_window_floating";
    "Alt + X" = {
      binding_mode = "move";
    };
    "Alt + G" = {
      binding_mode = "locked";
    };
    "Alt + H" = {
      move_focus = "left";
    };
    "Alt + J" = {
      move_focus = "down";
    };
    "Alt + K" = {
      move_focus = "up";
    };
    "Alt + L" = {
      move_focus = "right";
    };
    "Alt + Shift + H" = {
      move_node = "left";
    };
    "Alt + Shift + J" = {
      move_node = "down";
    };
    "Alt + Shift + K" = {
      move_node = "up";
    };
    "Alt + Shift + L" = {
      move_node = "right";
    };
    "Alt + R" = {
      binding_mode = "resize";
    };
    "Alt + 1" = {
      switch_to_workspace = 0;
    };
    "Alt + 2" = {
      switch_to_workspace = 1;
    };
    "Alt + 3" = {
      switch_to_workspace = 2;
    };
    "Alt + C" = {
      switch_to_workspace = 3;
    };
    "Alt + M" = {
      switch_to_workspace = 4;
    };
    "Alt + Shift + 1" = {
      move_window_to_workspace = {
        workspace = 0;
        follow = true;
      };
    };
    "Alt + Shift + 2" = {
      move_window_to_workspace = {
        workspace = 1;
        follow = true;
      };
    };
    "Alt + Shift + 3" = {
      move_window_to_workspace = {
        workspace = 2;
        follow = true;
      };
    };
    "Alt + Shift + C" = {
      move_window_to_workspace = {
        workspace = 3;
        follow = true;
      };
    };
    "Alt + Shift + M" = {
      move_window_to_workspace = {
        workspace = 4;
        follow = true;
      };
    };
    "Alt + Tab" = {
      next_workspace = false;
    };
    "Alt + Shift + Tab" = {
      prev_workspace = false;
    };
    "Alt + P" = "switch_to_last_workspace";
    "Alt + F" = "toggle_fullscreen_within_gaps";
    "Alt + Shift + F" = "toggle_fullscreen";
  };
  settings = {
    settings = {
      default_disable = false;
      hot_reload = true;
      run_on_start = [
        "${riftCli} subscribe cli --event workspace_changed --command ${notifyScript}"
        "${riftCli} subscribe cli --event binding_mode_changed --command ${notifyScript}"
      ];
      layout = {
        mode = "traditional";
        stack.default_orientation = "vertical";
        gaps = {
          inner = {
            horizontal = 16;
            vertical = 16;
          };
          outer = {
            left = 16;
            right = 16;
            top = 62;
            bottom = 14;
          };
        };
      };
    };
    virtual_workspaces = {
      enabled = true;
      mode = "global";
      default_workspace_count = 5;
      workspace_names = [
        "1"
        "2"
        "3"
        "C"
        "M"
      ];
      preserve_focus_per_workspace = true;
      workspace_auto_back_and_forth = true;
      prevent_wrapping = false;
      app_rules = [
        {
          app_id = "com.hnc.Discord";
          workspace = "C";
        }
        {
          app_id = "com.tinyspeck.slackmacgap";
          workspace = "C";
        }
        {
          app_id = "com.apple.iBooksX";
          workspace = "M";
        }
        {
          app_id = "com.apple.Music";
          workspace = "M";
        }
        {
          app_id = "com.apple.Podcasts";
          workspace = "M";
        }
        {
          app_name = "Audible";
          title_substring = "Audible Cloud Player";
          workspace = "M";
        }
      ]
      ++ map (app_id: {
        inherit app_id;
        floating = true;
      }) floatingApps;
    };
    keys = commands;
    binding_modes = {
      move = {
        Escape = exitMode;
        Enter = exitMode;
        "Alt + Escape" = exitMode;
        "Alt + H" = {
          move_node = "left";
        };
        "Alt + J" = {
          move_node = "down";
        };
        "Alt + K" = {
          move_node = "up";
        };
        "Alt + L" = {
          move_node = "right";
        };
      };
      locked = {
        "Alt + Escape" = exitMode;
      };
      resize = {
        Escape = exitMode;
        Enter = exitMode;
        "Alt + Escape" = exitMode;
        H = {
          resize_window_shrink = "horizontal";
        };
        J = {
          resize_window_grow = "vertical";
        };
        K = {
          resize_window_shrink = "vertical";
        };
        L = {
          resize_window_grow = "horizontal";
        };
        "Alt + H" = {
          resize_window_shrink = "horizontal";
        };
        "Alt + J" = {
          resize_window_grow = "vertical";
        };
        "Alt + K" = {
          resize_window_shrink = "vertical";
        };
        "Alt + L" = {
          resize_window_grow = "horizontal";
        };
      };
    };
  };
  riftConfig = format.generate "rift-config.toml" settings;
in
{
  options.sysinit.darwin.rift.settings = lib.mkOption {
    inherit (format) type;
    default = { };
    description = "Rift configuration managed by sysinit.";
  };

  config = {
    sysinit.darwin.rift.settings = settings;

    environment.systemPackages = [ pkgs.rift ];

    home-manager.users.${user} = {
      sysinit.codesign = {
        binaries.rift = "${pkgs.rift}/bin/rift";
        protectRunningApps = [ "rift" ];
      };

      xdg.configFile."rift/config.toml".source = riftConfig;
    };

    launchd.user.agents.rift.serviceConfig = {
      Label = "org.nixos.rift";
      ProgramArguments = [ "${home.sysinit.codesign.signedBinDir}/rift" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/rift.log";
      StandardErrorPath = "/tmp/rift.error.log";
    };
  };
}
