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
  toggleScrolling = pkgs.writeShellScript "rift-toggle-scrolling" ''
    set -euo pipefail
    layout="$(${riftCli} query workspace-layout | ${pkgs.jq}/bin/jq -er 'map(select(.is_active)) | first | .layout_mode')"
    if [ "$layout" = scrolling ]; then
      exec ${riftCli} execute workspace set-layout traditional
    fi
    exec ${riftCli} execute workspace set-layout scrolling
  '';
  notifyScript = pkgs.writeShellScript "rift-sketchybar-event" ''
    set -euo pipefail
    notify_mode() {
      local binding_mode layout target_mode mode
      binding_mode="$(${riftCli} query binding-mode | ${pkgs.jq}/bin/jq -r '.')"
      case "$binding_mode" in
        default|scroll)
          layout="$(${riftCli} query workspace-layout | ${pkgs.jq}/bin/jq -er 'map(select(.is_active)) | first | .layout_mode')"
          target_mode=default
          if [ "$layout" = scrolling ]; then
            target_mode=scroll
          fi
          if [ "$binding_mode" != "$target_mode" ]; then
            ${riftCli} execute binding-mode "$target_mode"
            binding_mode="$target_mode"
          fi
          ;;
      esac
      if [ "$binding_mode" = default ]; then
        mode=MAIN
      else
        mode="''${binding_mode^^}"
      fi
      ${sketchybar} --trigger rift_mode_changed MODE="$mode"
    }
    case "''${RIFT_EVENT_TYPE:-}" in
      workspace_changed)
        ${sketchybar} --trigger rift_workspace_changed FOCUSED="''${RIFT_WORKSPACE_NAME:-}"
        notify_mode
        ;;
      binding_mode_changed|layout_changed|config_changed|"")
        notify_mode
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
    "Alt + N" = {
      exec = [ "${toggleScrolling}" ];
    };

    "Alt + Up" = "ascend";
    "Alt + Down" = "descend";
    "Alt + Space" = "toggle_focus_floating";
    "Alt + Enter" = {
      exec = [
        "${pkgs.sysinit-utils}/bin/wezspawn"
        "--wezterm"
        "${pkgs.wezterm}/bin/wezterm"
        "--gui-app"
        weztermApp
      ];
    };

    "Alt + E" = [
      {
        set_workspace_layout = {
          mode = "traditional";
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
    "Alt + 4" = {
      switch_to_workspace = 3;
    };
    "Alt + 5" = {
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
    "Alt + Shift + 4" = {
      move_window_to_workspace = {
        workspace = 3;
        follow = true;
      };
    };
    "Alt + Shift + 5" = {
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
      animate = true;
      animation_duration = 0.12;
      animation_fps = 120.0;
      focus_follows_mouse = false;
      default_disable = false;
      hot_reload = true;
      gestures = {
        enabled = true;
        consume_dock_swipe = true;
        fingers = 3;
        skip_empty = false;
      };
      ui.stack_line.enabled = false;
      ui.menu_bar = {
        enabled = true;
        show_empty = false;
      };
      run_on_start = [
        "${riftCli} subscribe cli --event workspace_changed --command ${notifyScript}"
        "${riftCli} subscribe cli --event binding_mode_changed --command ${notifyScript}"
        "${riftCli} subscribe cli --event layout_changed --command ${notifyScript}"
        "${riftCli} subscribe cli --event config_changed --command ${notifyScript}"
        "${notifyScript}"
      ];
      layout = {
        mode = "traditional";
        window_insertion_point = "next_to_selection";
        traditional.equalize_nodes = true;
        scrolling = {
          column_width_ratio = 0.5;
          preserve_window_sizes = false;
          expand_single_column = true;
          min_column_width_ratio = 0.3;
          max_column_width_ratio = 1.0;
          preset_column_widths = [
            (1.0 / 3.0)
            0.5
            (2.0 / 3.0)
            1.0
          ];
          focus_navigation_style = "niri";
        };
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
        "4"
        "5"
      ];
      preserve_focus_per_workspace = true;
      workspace_auto_back_and_forth = true;
      prevent_wrapping = false;
      app_rules = [
        {
          app_id = "com.github.wez.wezterm";
          floating = false;
          focus = true;
        }
      ]
      ++ map (app_id: {
        inherit app_id;
        floating = true;
      }) floatingApps;
    };
    keys = commands;
    binding_modes = {
      scroll = commands // {
        "Alt + Comma" = {
          switch_preset_column_width.backwards = true;
        };
        "Alt + Period" = "switch_preset_column_width";
        "Alt + I" = {
          consume_or_expel_window = "left";
        };
        "Alt + O" = {
          consume_or_expel_window = "right";
        };
        "Alt + U" = "center_selection";
      };
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
