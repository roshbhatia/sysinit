{
  config,
  lib,
  pkgs,
  ...
}:

let
  desktopLayout = import ./desktop-layout.nix;
  format = pkgs.formats.toml { };
  home = config.home-manager.users.${config.sysinit.user.username};
  user = config.sysinit.user.username;
  weztermApp = "${home.home.homeDirectory}/${home.targets.darwin.copyApps.directory}/WezTerm.app";
  sketchybar = "${pkgs.sketchybar}/bin/sketchybar";
  riftCli = "${pkgs.rift}/bin/rift-cli";
  transientView = pkgs.writeShellApplication {
    name = "rift-view";
    runtimeInputs = [ pkgs.nushell ];
    text = ''
      exec nu --no-config-file ${./rift-transient-view.nu} --rift-cli ${riftCli} -- "$@"
    '';
  };
  viewCommand = args: { exec = [ (lib.getExe transientView) ] ++ args; };
  focusWindow =
    direction:
    viewCommand [
      "focus"
      direction
    ];
  switchWorkspace =
    id:
    viewCommand [
      "run"
      "workspace"
      "switch"
      (toString id)
    ];
  moveToWorkspace =
    id:
    viewCommand [
      "run"
      "workspace"
      "move-window"
      (toString id)
      "--follow"
    ];
  resizeWindow =
    command: orientation:
    viewCommand [
      "run"
      "window"
      command
      "--orientation"
      orientation
    ];
  windowCommand =
    command:
    viewCommand [
      "run"
      "window"
      command
    ];
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
    "Alt + N" = viewCommand [ "toggle-scrolling" ];

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

    "Alt + E" = viewCommand [
      "layout"
      "traditional"
      "toggle-orientation"
    ];

    "Alt + S" = viewCommand [
      "layout"
      "stack"
    ];
    "Alt + W" = viewCommand [
      "layout"
      "stack"
      "toggle-orientation"
    ];
    "Alt + Shift + Space" = windowCommand "toggle-float";
    "Alt + X" = {
      binding_mode = "move";
    };
    "Alt + G" = {
      binding_mode = "locked";
    };
    "Alt + H" = focusWindow "left";
    "Alt + J" = focusWindow "down";
    "Alt + K" = focusWindow "up";
    "Alt + L" = focusWindow "right";
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
    "Alt + 1" = switchWorkspace 0;
    "Alt + 2" = switchWorkspace 1;
    "Alt + 3" = switchWorkspace 2;
    "Alt + 4" = switchWorkspace 3;
    "Alt + 5" = switchWorkspace 4;
    "Alt + Shift + 1" = moveToWorkspace 0;
    "Alt + Shift + 2" = moveToWorkspace 1;
    "Alt + Shift + 3" = moveToWorkspace 2;
    "Alt + Shift + 4" = moveToWorkspace 3;
    "Alt + Shift + 5" = moveToWorkspace 4;
    "Alt + Tab" = viewCommand [
      "run"
      "workspace"
      "next"
      "false"
    ];
    "Alt + Shift + Tab" = viewCommand [
      "run"
      "workspace"
      "prev"
      "false"
    ];
    "Alt + P" = viewCommand [
      "run"
      "workspace"
      "last"
    ];
    "Alt + F" = windowCommand "toggle-fullscreen-within-gaps";
    "Alt + Shift + F" = windowCommand "toggle-fullscreen";
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
            horizontal = desktopLayout.gap;
            vertical = desktopLayout.gap;
          };
          outer = {
            left = desktopLayout.gap;
            right = desktopLayout.gap;
            top = desktopLayout.barHeight + 2 * desktopLayout.gap;
            bottom = desktopLayout.gap;
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
        "Alt + Comma" = viewCommand [
          "run"
          "layout"
          "switch-preset-column-width"
          "--backwards"
        ];
        "Alt + Period" = viewCommand [
          "run"
          "layout"
          "switch-preset-column-width"
        ];
        "Alt + I" = {
          consume_or_expel_window = "left";
        };
        "Alt + O" = {
          consume_or_expel_window = "right";
        };
        "Alt + U" = viewCommand [ "reading" ];
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
        H = resizeWindow "resize-shrink" "horizontal";
        J = resizeWindow "resize-grow" "vertical";
        K = resizeWindow "resize-shrink" "vertical";
        L = resizeWindow "resize-grow" "horizontal";
        "Alt + H" = resizeWindow "resize-shrink" "horizontal";
        "Alt + J" = resizeWindow "resize-grow" "vertical";
        "Alt + K" = resizeWindow "resize-shrink" "vertical";
        "Alt + L" = resizeWindow "resize-grow" "horizontal";
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
