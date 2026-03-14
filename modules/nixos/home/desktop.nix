# NixOS desktop home-manager configuration: sway, waybar, rofi, mako, nemo
{
  config,
  lib,
  pkgs,
  values,
  ...
}:

let
  colors = config.lib.stylix.colors;

  wallpaper = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/diinki/linux-retroism/main/wallpapers/copyleft.png";
    sha256 = "1vjf8dq4dzbym9a5sk29cfbr83mlz5manx6n9hq2jkaniw3yvxax";
  };

  mod = "Mod1"; # Alt key
in
{
  stylix.targets = {
    waybar.enable = false;
    rofi.enable = false;
    mako.enable = false;
    sway.enable = false;
  };

  # === Sway Window Manager ===
  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;

    config = {
      modifier = mod;
      terminal = "wezterm";
      menu = "${pkgs.rofi}/bin/rofi -show drun -theme ~/.config/rofi/config.rasi";

      fonts = {
        names = [ "${values.theme.font.monospace}" ];
        size = 11.0;
      };

      # Flat retro aesthetic
      gaps = {
        inner = 0;
        outer = 0;
      };
      defaultWorkspace = "workspace number 1";

      # Input devices
      input = {
        "type:keyboard" = {
          xkb_layout = "us";
          repeat_rate = "50";
          repeat_delay = "300";
        };
        "type:pointer" = {
          accel_profile = "flat";
          pointer_accel = "-0.5";
        };
        "type:touchpad" = {
          natural_scroll = "enabled";
          tap = "enabled";
          dwt = "enabled";
        };
      };

      # Wallpaper
      output = {
        "*" = {
          bg = "$HOME/.background-image fill";
        };
      };

      # Window appearance
      window = {
        border = 1;
        titlebar = false;
      };
      floating = {
        border = 1;
        titlebar = false;
      };
      colors = {
        focused = {
          border = "#${colors.base0D}";
          background = "#${colors.base0D}";
          text = "#${colors.base00}";
          indicator = "#${colors.base0D}";
          childBorder = "#${colors.base0D}";
        };
        unfocused = {
          border = "#${colors.base01}";
          background = "#${colors.base01}";
          text = "#${colors.base05}";
          indicator = "#${colors.base01}";
          childBorder = "#${colors.base01}";
        };
      };

      # Floating modifier (Super for mouse move/resize)
      floating.modifier = "Mod4";

      # Autostart
      startup = [
        { command = "dbus-update-activation-environment --systemd --all"; }
        { command = "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"; }
        { command = "${pkgs.mako}/bin/mako"; }
        { command = "${pkgs.waybar}/bin/waybar"; }
        { command = "nm-applet --indicator"; }
      ];

      # Window assignment rules
      assigns = {
        "C" = [
          { class = "^discord$"; }
          { class = "^Slack$"; }
          { class = "^ferdium$"; }
        ];
        "E" = [
          { class = "^thunderbird$"; }
        ];
        "M" = [
          { class = "^Spotify$"; }
          { app_id = "^spotify$"; }
        ];
      };

      # Floating rules
      window.commands = [
        { command = "floating enable"; criteria = { title = "^Picture-in-Picture$"; }; }
        { command = "floating enable"; criteria = { class = "^pavucontrol$"; }; }
        { command = "floating enable"; criteria = { app_id = "^pavucontrol$"; }; }
        { command = "floating enable"; criteria = { class = "^1Password$"; }; }
        { command = "floating enable"; criteria = { app_id = "^1password$"; }; }
        { command = "floating enable"; criteria = { class = "^nemo$"; }; }
        { command = "floating enable"; criteria = { app_id = "^nemo$"; }; }
      ];

      # === Keybindings (default mode) ===
      keybindings = lib.mkOptionDefault {
        # Terminal
        "${mod}+Return" = "exec wezterm";

        # App launcher (Super+Space)
        "Mod4+space" = "exec ${pkgs.rofi}/bin/rofi -show drun -theme ~/.config/rofi/config.rasi";

        # Kill window (Super+Q)
        "Mod4+q" = "kill";

        # Exit sway (Super+Shift+Q)
        "Mod4+Shift+q" = "exec swaymsg exit";

        # Window focus (vim-style)
        "${mod}+h" = "focus left";
        "${mod}+j" = "focus down";
        "${mod}+k" = "focus up";
        "${mod}+l" = "focus right";

        # Resize
        "${mod}+Shift+j" = "resize shrink height 72 px";
        "${mod}+Shift+k" = "resize grow height 72 px";

        # Workspaces (named, matching Mac Aerospace)
        "${mod}+1" = "workspace 1";
        "${mod}+2" = "workspace 2";
        "${mod}+c" = "workspace C";
        "${mod}+e" = "workspace E";
        "${mod}+m" = "workspace M";

        # Move to workspace (with focus follow)
        "${mod}+Shift+1" = "move container to workspace 1; workspace 1";
        "${mod}+Shift+2" = "move container to workspace 2; workspace 2";
        "${mod}+Shift+c" = "move container to workspace C; workspace C";
        "${mod}+Shift+e" = "move container to workspace E; workspace E";
        "${mod}+Shift+m" = "move container to workspace M; workspace M";

        # Workspace cycling
        "${mod}+Tab" = "workspace next_on_output";
        "${mod}+Shift+Tab" = "workspace prev_on_output";

        # Workspace back-and-forth
        "${mod}+p" = "workspace back_and_forth";

        # Fullscreen
        "${mod}+f" = "fullscreen toggle";

        # Float toggle
        "${mod}+v" = "floating toggle";

        # Layout toggle (tiles h/v)
        "${mod}+t" = "layout toggle split";

        # Enter move mode
        "${mod}+x" = "mode move";

        # Enter locked mode (passthrough)
        "${mod}+g" = "mode locked";
      };

      # === Modes ===
      modes = {
        move = {
          "${mod}+h" = "move left";
          "${mod}+j" = "move down";
          "${mod}+k" = "move up";
          "${mod}+l" = "move right";
          "Escape" = "mode default";
        };
        locked = {
          "${mod}+g" = "mode default";
        };
      };

      # Bars are managed by waybar, not sway's built-in bar
      bars = [ ];
    };

    extraSessionCommands = ''
      export NIXOS_OZONE_WL=1
      export GDK_BACKEND=wayland
      export QT_QPA_PLATFORM=wayland
      export MOZ_ENABLE_WAYLAND=1
    '';
  };

  # === Rofi App Launcher ===
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
      bg:          #c0c0c0;
      bg-light:    #d8d8d8;
      border-col:  #000000;
      selected:    #000080;
      fg:          #000000;
      fg-light:    #ffffff;
    }

    window {
      width: 400px;
      border: 2px;
      border-color: @border-col;
      background-color: @bg;
      border-radius: 0px;
    }

    mainbox {
      background-color: @bg;
      children: [ inputbar, listview ];
    }

    inputbar {
      background-color: @bg;
      children: [ prompt, entry ];
      padding: 6px;
      border: 0 0 2px 0;
      border-color: @border-col;
    }

    prompt {
      background-color: @selected;
      text-color: @fg-light;
      padding: 4px 8px;
      font: "${values.theme.font.monospace} 12";
    }

    entry {
      background-color: @bg-light;
      text-color: @fg;
      padding: 4px 8px;
      placeholder: "Search...";
      font: "${values.theme.font.monospace} 12";
      border: 2px solid;
      border-color: #808080 #ffffff #ffffff #808080;
    }

    listview {
      background-color: @bg;
      columns: 1;
      lines: 8;
      padding: 4px;
      spacing: 2px;
    }

    element {
      background-color: @bg;
      text-color: @fg;
      padding: 4px 8px;
      border-radius: 0px;
    }

    element selected {
      background-color: @selected;
      text-color: @fg-light;
    }

    element-icon {
      size: 20px;
      background-color: inherit;
    }

    element-text {
      background-color: inherit;
      text-color: inherit;
      font: "${values.theme.font.monospace} 12";
    }
  '';

  # === Waybar Status Bar ===
  programs.waybar = {
    enable = true;
    systemd.enable = false;

    settings.mainBar = {
      layer = "top";
      position = "top";
      exclusive = true;
      passthrough = false;
      height = 28;
      spacing = 0;
      margin-top = 0;
      margin-left = 0;
      margin-right = 0;

      modules-left = [
        "custom/logo"
        "custom/sep"
        "sway/workspaces"
      ];
      modules-center = [ ];
      modules-right = [
        "pulseaudio"
        "network"
        "cpu"
        "memory"
        "clock"
        "clock#utc"
        "tray"
      ];

      "custom/logo" = {
        format = " Start";
        tooltip = false;
        on-click = "${pkgs.rofi}/bin/rofi -show drun -theme ~/.config/rofi/config.rasi";
      };
      "custom/sep" = {
        format = "|";
        tooltip = false;
      };
      "sway/workspaces" = {
        disable-scroll = true;
        all-outputs = true;
        format = "{name}";
      };
      clock = {
        format = "{:%H:%M}";
        tooltip-format = "<tt>{calendar}</tt>";
      };
      "clock#utc" = {
        format = "{:%H:%M UTC}";
        timezone = "UTC";
        tooltip = false;
      };
      cpu = {
        format = " CPU {usage}% ";
        interval = 2;
      };
      memory = {
        format = " MEM {percentage}% ";
        interval = 2;
      };
      network = {
        format-wifi = " WiFi ";
        format-ethernet = " ETH ";
        format-disconnected = " OFF ";
      };
      pulseaudio = {
        format = " VOL {volume}% ";
        format-muted = " MUTE ";
        on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
      };
      tray = {
        spacing = 8;
      };
    };

    style = ''
      * {
        font-family: "${values.theme.font.monospace}", monospace;
        font-size: 13px;
        min-height: 0;
        padding: 0;
        margin: 0;
      }
      window#waybar {
        background: #c0c0c0;
        color: #000000;
        border-bottom: 1px solid #808080;
      }

      /* Raised 3D button style (outset bevel) */
      #custom-logo {
        padding: 0 8px;
        margin: 2px 2px;
        font-weight: bold;
        color: #000000;
        background: #c0c0c0;
        border: 2px solid;
        border-top-color: #ffffff;
        border-left-color: #ffffff;
        border-right-color: #404040;
        border-bottom-color: #404040;
      }

      #custom-sep {
        color: #808080;
        padding: 0 2px;
      }

      /* Workspace buttons: raised 3D */
      #workspaces button {
        padding: 0 6px;
        margin: 2px 1px;
        color: #000000;
        background: #c0c0c0;
        border: 2px solid;
        border-top-color: #ffffff;
        border-left-color: #ffffff;
        border-right-color: #404040;
        border-bottom-color: #404040;
        border-radius: 0;
      }

      /* Active workspace: pressed/sunken 3D (inverted bevel) */
      #workspaces button.focused {
        background: #000080;
        color: #ffffff;
        border-top-color: #404040;
        border-left-color: #404040;
        border-right-color: #ffffff;
        border-bottom-color: #ffffff;
      }

      /* Sunken field style for status indicators */
      #clock, #cpu, #memory, #network, #pulseaudio {
        padding: 0 6px;
        margin: 2px 1px;
        background: #c0c0c0;
        border: 2px solid;
        border-top-color: #808080;
        border-left-color: #808080;
        border-right-color: #ffffff;
        border-bottom-color: #ffffff;
      }

      #clock {
        font-weight: bold;
      }

      /* System tray: sunken */
      #tray {
        padding: 0 6px;
        margin: 2px 2px;
        border: 2px solid;
        border-top-color: #808080;
        border-left-color: #808080;
        border-right-color: #ffffff;
        border-bottom-color: #ffffff;
        background: #c0c0c0;
      }

      tooltip {
        background: #c0c0c0;
        border: 2px solid #000000;
        border-radius: 0;
      }
      tooltip label {
        color: #000000;
        padding: 4px;
      }
    '';
  };

  # === Mako Notifications ===
  services.mako = {
    enable = true;
    settings = {
      font = "${values.theme.font.monospace} 11";
      background-color = "#c0c0c0";
      text-color = "#000000";
      border-color = "#000000";
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
