# NixOS desktop home-manager configuration: niri, quickshell, rofi, mako, nemo
{
  config,
  lib,
  pkgs,
  values,
  inputs,
  ...
}:

let
  colors = config.lib.stylix.colors;

  wallpaper = pkgs.fetchurl {
    url = "https://images2.alphacoders.com/140/1406218.png";
    sha256 = "0000000000000000000000000000000000000000000000000000";
  };

  mod = "Mod1"; # Alt key
  sup = "Mod4"; # Super key

  modeFile = "$HOME/.cache/niri-mode";

  writeMode = mode: ''spawn "sh" "-c" "echo ${mode} > ${modeFile}"'';
in
{
  imports = [
    inputs.niri-flake.homeModules.niri
  ];

  stylix.targets = {
    rofi.enable = false;
    mako.enable = false;
  };

  # === Niri Window Manager ===
  programs.niri = {
    enable = true;

    config = ''
      input {
        keyboard {
          xkb {
            layout "us"
          }
          repeat-rate 50
          repeat-delay 300
        }

        mouse {
          accel-profile "flat"
          accel-speed -0.5
        }

        touchpad {
          natural-scroll
          tap
          dwt
        }
      }

      output "*" {
        background-color "#1d2021"
      }

      layout {
        gaps 13

        focus-ring {
          width 2
          active-color "#83a598"
          inactive-color "#665c54"
        }

        border {
          off
        }

        preset-column-widths {
          proportion 0.33333
          proportion 0.5
          proportion 0.66667
        }

        default-column-width {
          proportion 0.5
        }
      }

      prefer-no-csd

      cursor {
        hide-when-typing
        hide-after-inactive-ms 10000
      }

      spawn-at-startup "sh" "-c" "echo MAIN > ${modeFile}"
      spawn-at-startup "${pkgs.dbus}/bin/dbus-update-activation-environment" "--systemd" "--all"
      spawn-at-startup "systemctl" "--user" "import-environment" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP"
      spawn-at-startup "${pkgs.mako}/bin/mako"
      spawn-at-startup "nm-applet" "--indicator"

      hotkey-overlay {
        skip-at-startup
      }

      binds {
        // Terminal
        ${mod}+Return { spawn "wezterm"; }

        // App launcher
        ${sup}+Space { spawn "${pkgs.rofi}/bin/rofi" "-show" "drun" "-theme" "${config.xdg.configHome}/rofi/config.rasi"; }

        // Close window
        ${sup}+Q { close-window; }

        // Focus (vim-style)
        ${mod}+H { focus-column-left; }
        ${mod}+J { focus-window-down; }
        ${mod}+K { focus-window-up; }
        ${mod}+L { focus-column-right; }

        // Resize
        ${mod}+Shift+J { set-column-width "-10%"; }
        ${mod}+Shift+K { set-column-width "+10%"; }

        // Maximize / fullscreen
        ${mod}+F { maximize-column; }
        ${mod}+Shift+F { fullscreen-window; }

        // Center column
        ${mod}+C { center-column; }

        // Consume / expel windows into/from column
        ${mod}+Comma { consume-window-into-column; }
        ${mod}+Period { expel-window-from-column; }

        // Column width presets
        ${mod}+R { switch-preset-column-width; }

        // Float toggle
        ${mod}+V { toggle-window-floating; }

        // Workspaces
        ${mod}+1 { focus-workspace 1; }
        ${mod}+2 { focus-workspace 2; }
        ${mod}+3 { focus-workspace 3; }
        ${mod}+4 { focus-workspace 4; }
        ${mod}+5 { focus-workspace 5; }
        ${mod}+6 { focus-workspace 6; }
        ${mod}+7 { focus-workspace 7; }
        ${mod}+8 { focus-workspace 8; }
        ${mod}+9 { focus-workspace 9; }

        // Move to workspace
        ${mod}+Shift+1 { move-column-to-workspace 1; }
        ${mod}+Shift+2 { move-column-to-workspace 2; }
        ${mod}+Shift+3 { move-column-to-workspace 3; }
        ${mod}+Shift+4 { move-column-to-workspace 4; }
        ${mod}+Shift+5 { move-column-to-workspace 5; }
        ${mod}+Shift+6 { move-column-to-workspace 6; }
        ${mod}+Shift+7 { move-column-to-workspace 7; }
        ${mod}+Shift+8 { move-column-to-workspace 8; }
        ${mod}+Shift+9 { move-column-to-workspace 9; }

        // Workspace cycling
        ${mod}+Tab { focus-workspace-down; }
        ${mod}+Shift+Tab { focus-workspace-up; }

        // Move columns/windows (replaces sway move mode)
        ${mod}+Ctrl+H { move-column-left; }
        ${mod}+Ctrl+J { move-window-down; }
        ${mod}+Ctrl+K { move-window-up; }
        ${mod}+Ctrl+L { move-column-right; }

        // Monitor focus
        ${mod}+Shift+H { focus-monitor-left; }
        ${mod}+Shift+L { focus-monitor-right; }

        // Move column to monitor
        ${mod}+Ctrl+Shift+H { move-column-to-monitor-left; }
        ${mod}+Ctrl+Shift+L { move-column-to-monitor-right; }

        // Volume keys (work when locked)
        XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05+"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05-"; }
        XF86AudioMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }

        // Screenshot
        Print { screenshot; }
      }
    '';
  };

  # === Rofi App Launcher (Gruvbox) ===
  xdg.configFile."rofi/config.rasi".text = ''
    configuration {
      modi: "drun,run,window";
      show-icons: true;
      terminal: "wezterm";
      drun-display-format: "{icon} {name}";
      disable-history: false;
      hide-scrollbar: true;
      sorting-method: "fzf";
    }

    * {
      bg:          #1d2021e6;
      bg-solid:    #1d2021;
      bg-alt:      #282828;
      fg:          #ebdbb2;
      fg-dim:      #928374;
      accent:      #fe8019;
      accent-alt:  #fabd2f;
      urgent:      #fb4934;
      border-col:  #504945;
    }

    window {
      width: 480px;
      border: 2px;
      border-color: @border-col;
      background-color: @bg;
      border-radius: 6px;
      padding: 0;
    }

    mainbox {
      background-color: transparent;
      children: [ inputbar, message, listview ];
      spacing: 0;
    }

    inputbar {
      background-color: @bg-alt;
      children: [ prompt, entry ];
      padding: 12px 16px;
      border: 0 0 1px 0;
      border-color: @border-col;
      border-radius: 6px 6px 0 0;
    }

    prompt {
      background-color: @accent;
      text-color: @bg-solid;
      padding: 6px 12px;
      border-radius: 4px;
      font: "${values.theme.font.monospace} 13";
    }

    entry {
      background-color: transparent;
      text-color: @fg;
      padding: 6px 12px;
      placeholder: "Search...";
      placeholder-color: @fg-dim;
      font: "${values.theme.font.monospace} 13";
    }

    message {
      background-color: transparent;
      border: 0;
      padding: 8px 16px;
    }

    textbox {
      text-color: @fg-dim;
      background-color: transparent;
    }

    listview {
      background-color: transparent;
      columns: 1;
      lines: 10;
      padding: 8px 0;
      spacing: 0;
      fixed-height: true;
    }

    element {
      background-color: transparent;
      text-color: @fg;
      padding: 10px 16px;
      border-radius: 0;
    }

    element selected {
      background-color: @accent;
      text-color: @bg-solid;
    }

    element urgent {
      text-color: @urgent;
    }

    element active {
      text-color: @accent-alt;
    }

    element-icon {
      size: 22px;
      background-color: inherit;
      padding: 0 8px 0 0;
    }

    element-text {
      background-color: inherit;
      text-color: inherit;
      font: "${values.theme.font.monospace} 13";
      vertical-align: 0.5;
    }
  '';

  # === Mako Notifications (Gruvbox) ===
  services.mako = {
    enable = true;
    settings = {
      font = "${values.theme.font.monospace} 11";
      background-color = "#1d2021";
      text-color = "#ebdbb2";
      border-color = "#504945";
      border-size = 2;
      border-radius = 0;
      padding = "15";
      margin = "10";
      width = 350;
      height = 100;
      default-timeout = 5000;
      layer = "overlay";
    };

    extraConfig = ''
      [urgency=low]
      border-color=#${colors.base03}

      [urgency=high]
      border-color=#${colors.base08}
      default-timeout=0
    '';
  };

  # === Wallpaper ===
  home.file.".background-image" = {
    source = wallpaper;
    force = true;
  };

  # === Nemo File Manager ===
  home.file.".local/share/nemo/actions/open-terminal.nemo_action".text = ''
    [Nemo Action]
    Active=true
    Name=Open Terminal Here
    Exec=wezterm -e bash -c "cd %f && bash"
    Selection=Any
    Extensions=any;
  '';

  dconf.settings = {
    "org/cinnamon/desktop/default-applications/terminal".exec = "wezterm";
    "org/nemo/preferences" = {
      show-hidden-files = false;
      show-advanced-permissions = true;
      date-format = "informal";
      default-folder-viewer = "icon-view";
    };
    "org/nemo/window-state" = {
      geometry = "1200x800+50+50";
      sidebar-width = 200;
    };
  };
}
