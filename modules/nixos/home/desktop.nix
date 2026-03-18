{
  config,
  lib,
  pkgs,
  ...
}:

let
  c = config.lib.stylix.colors;
  mod = "Mod1"; # Alt key

  # 1Password quick access via rofi — search items, pick field, copy to clipboard
  rofi1password = pkgs.writeShellScript "rofi-1password" ''
    set -euo pipefail

    # Check if signed in
    if ! ${pkgs._1password-cli}/bin/op account list &>/dev/null; then
      ${pkgs.libnotify}/bin/notify-send "1Password" "Not signed in. Run: op signin" --urgency=critical
      exit 1
    fi

    # List items from 1Password
    ITEM=$(${pkgs._1password-cli}/bin/op item list --format=json 2>/dev/null \
      | ${pkgs.jq}/bin/jq -r '.[] | "\(.title) [\(.category)]"' \
      | ${pkgs.rofi}/bin/rofi -dmenu -p "  1Password" -i) || exit 0

    [ -z "$ITEM" ] && exit 0

    # Extract the title (strip the category suffix)
    TITLE=$(echo "$ITEM" | ${pkgs.gnused}/bin/sed 's/ \[.*\]$//')

    # Choose which field to copy
    FIELD=$(printf "password\nusername\notp" | ${pkgs.rofi}/bin/rofi -dmenu -p "Copy field") || exit 0

    [ -z "$FIELD" ] && exit 0

    # Get the field value and copy to clipboard
    if [ "$FIELD" = "otp" ]; then
      VALUE=$(${pkgs._1password-cli}/bin/op item get "$TITLE" --otp 2>/dev/null)
    else
      VALUE=$(${pkgs._1password-cli}/bin/op item get "$TITLE" --fields "$FIELD" 2>/dev/null)
    fi

    if [ -n "$VALUE" ]; then
      echo -n "$VALUE" | ${pkgs.wl-clipboard}/bin/wl-copy
      ${pkgs.libnotify}/bin/notify-send "1Password" "Copied $FIELD for $TITLE"
    else
      ${pkgs.libnotify}/bin/notify-send "1Password" "No $FIELD found for $TITLE" --urgency=critical
    fi
  '';

  wallpaper = pkgs.fetchurl {
    url = "https://wallpapercave.com/wp/wp12329549.png";
    sha256 = "sha256-9R3cDgd1VslCF6mG6jBO64MEdRjCGzWE4m/dAjEixzk=";
  };
in
{
  wayland = {
    windowManager.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      checkConfig = false;

      config = {
        modifier = mod;
        terminal = "${pkgs.wezterm}/bin/wezterm start";
        menu = "${pkgs.rofi}/bin/rofi -show drun";

        fonts = {
          names = lib.mkForce [ "${config.sysinit.theme.font.monospace}" ];
          size = lib.mkForce 11.0;
        };

        gaps = {
          inner = 16;
          outer = 200;
          top = 100;
          bottom = 100;
        };

        defaultWorkspace = "workspace number 1";

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

        output = {
          "*" = {
            bg = lib.mkForce "#${c.base00} solid_color";
            scale = "1";
          };
        };

        window = {
          border = 0;
          titlebar = false;
        };
        floating = {
          border = 1;
          titlebar = false;
        };

        floating.modifier = "Mod4";

        startup = [
          { command = "dbus-update-activation-environment --systemd --all"; }
          { command = "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"; }
          { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; }
          { command = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store"; }
          { command = "nm-applet --indicator"; }
          {
            command = "sh -c 'if [ -f ${config.home.homeDirectory}/.background-image ]; then swaymsg output \\* bg ${config.home.homeDirectory}/.background-image fill; else swaymsg output \\* bg ${wallpaper} fill; fi'";
          }
        ];

        assigns = {
          "C" = [
            { class = "^discord$"; }
            { class = "^Slack$"; }
            { app_id = "^vesktop$"; }
          ];
          "E" = [
            { class = "^thunderbird$"; }
          ];
          "M" = [
            { class = "^Spotify$"; }
            { app_id = "^spotify$"; }
            { app_id = "^cider$"; }
          ];
        };

        window.commands = [
          {
            command = "floating enable";
            criteria = {
              title = "^Picture-in-Picture$";
            };
          }
          {
            command = "floating enable";
            criteria = {
              class = "^pavucontrol$";
            };
          }
          {
            command = "floating enable";
            criteria = {
              app_id = "^pavucontrol$";
            };
          }
          {
            command = "floating enable";
            criteria = {
              class = "^1Password$";
            };
          }
          {
            command = "floating enable";
            criteria = {
              app_id = "^1password$";
            };
          }
          {
            command = "floating enable";
            criteria = {
              app_id = "^nemo$";
            };
          }
        ];

        keybindings = lib.mkForce {
          # Terminal
          "${mod}+Return" = "exec ${pkgs.wezterm}/bin/wezterm start";

          # App launcher
          "Mod4+space" = "exec ${pkgs.rofi}/bin/rofi -show drun";

          # 1Password quick access (like macOS Cmd+Shift+Space for 1Password)
          "Mod4+Shift+space" = "exec ${rofi1password}";

          # Kill / exit
          "Mod4+q" = "kill";
          "Mod4+Control+q" = "exec swaymsg exit";

          # macOS-like Super+key → Ctrl+key handled by kanata at evdev level

          # Minimize (move to scratchpad)
          "Mod4+h" = "move scratchpad";
          "Mod4+m" = "move scratchpad";

          # Focus (vim-style, matching aerospace)
          "${mod}+h" = "focus left";
          "${mod}+j" = "focus down";
          "${mod}+k" = "focus up";
          "${mod}+l" = "focus right";

          # Resize mode
          "${mod}+r" = "mode resize";

          # Workspaces (only 1, 2, C, E, M — matching aerospace)
          "${mod}+1" = "workspace 1";
          "${mod}+2" = "workspace 2";
          "${mod}+c" = "workspace C";
          "${mod}+e" = "workspace E";
          "${mod}+m" = "workspace M";

          "${mod}+Shift+1" = "move container to workspace 1; workspace 1";
          "${mod}+Shift+2" = "move container to workspace 2; workspace 2";
          "${mod}+Shift+c" = "move container to workspace C; workspace C";
          "${mod}+Shift+e" = "move container to workspace E; workspace E";
          "${mod}+Shift+m" = "move container to workspace M; workspace M";

          # Workspace cycling
          "${mod}+Tab" = "workspace next_on_output";
          "${mod}+Shift+Tab" = "workspace prev_on_output";
          "${mod}+p" = "workspace back_and_forth";

          # Fullscreen
          "${mod}+f" = "fullscreen toggle";

          # Float / layout
          "${mod}+v" = "floating toggle";
          "${mod}+t" = "layout toggle split";

          # Move mode (like aerospace)
          "${mod}+x" = "mode move";

          # Locked mode (passthrough, like aerospace)
          "${mod}+g" = "mode locked";

          # Clipboard history
          # Window switcher (macOS-style Cmd+Tab)
          "Mod4+Tab" = "exec ${pkgs.rofi}/bin/rofi -show window";
          "Mod4+Shift+Tab" = "exec ${pkgs.rofi}/bin/rofi -show window";

          # Clipboard history
          "${mod}+Shift+v" =
            "exec ${pkgs.cliphist}/bin/cliphist list | ${pkgs.rofi}/bin/rofi -dmenu | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy";

          # Color picker — click a pixel, hex color copied to clipboard
          "Mod4+Shift+c" =
            "exec ${pkgs.hyprpicker}/bin/hyprpicker -a -n && ${pkgs.libnotify}/bin/notify-send \"Color Picker\" \"Hex code copied to clipboard\" -i color-management";

          # Screenshots (macOS-style: Super+Shift+3 = screen, Super+Shift+4 = region)
          "Mod4+Shift+3" = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot --notify savecopy output";
          "Mod4+Shift+4" = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot --notify savecopy area";
          "Mod4+Shift+5" = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot --notify savecopy window";
          "Print" = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot --notify savecopy area";

          # Volume
          "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+";
          "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05-";
          "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "Mod4+a" = "exec audio-switcher";

          # Media
          "XF86AudioPlay" = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
          "XF86AudioPause" = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
          "XF86AudioNext" = "exec ${pkgs.playerctl}/bin/playerctl next";
          "XF86AudioPrev" = "exec ${pkgs.playerctl}/bin/playerctl previous";
        };

        modes = {
          move = {
            "${mod}+h" = "move left";
            "${mod}+j" = "move down";
            "${mod}+k" = "move up";
            "${mod}+l" = "move right";
            "Escape" = "mode default";
          };
          resize = {
            "${mod}+h" = "resize shrink width 72 px";
            "${mod}+j" = "resize grow height 72 px";
            "${mod}+k" = "resize shrink height 72 px";
            "${mod}+l" = "resize grow width 72 px";
            "Escape" = "mode default";
            "Return" = "mode default";
          };
          locked = {
            "${mod}+g" = "mode default";
          };
        };

        bars = [ ];
      };

      extraSessionCommands = ''
        export NIXOS_OZONE_WL=1
        export GDK_BACKEND=wayland
        export QT_QPA_PLATFORM=wayland
        export MOZ_ENABLE_WAYLAND=1
      '';

      # SwayFX effects (requires swayfx from flake, not nixpkgs)
      extraConfig = ''
        # Animations (swayfx — snappy resize/move)
        animation_duration_ms 150

        # Visual effects
        blur enable
        blur_passes 2
        blur_radius 5
        corner_radius 0
      smart_corner_radius off
        shadows enable
        shadow_blur_radius 20
        shadow_color #0000007F
        default_dim_inactive 0.1

        # Apply blur to waybar
        layer_effects "waybar" blur enable; shadows enable
      '';
    };
  };

  stylix.targets.waybar.addCss = false;

  programs = {
    waybar = {
      enable = true;
      systemd.enable = true;

      settings = [
        {
          layer = "top";
          position = "top";
          height = 32;
          spacing = 0;

          # Left: logo, mode, front app (matches sketchybar left side)
          modules-left = [
            "custom/logo"
            "sway/mode"
            "sway/window"
          ];
          # Center: workspaces (matches sketchybar center)
          modules-center = [ "sway/workspaces" ];
          # Right: clock, battery, volume (matches sketchybar right side)
          modules-right = [
            "clock"
            "battery"
            "pulseaudio"
          ];

          "custom/logo" = {
            format = "󱄅";
            tooltip = false;
          };

          "sway/mode" = {
            format = "{}";
          };

          "sway/window" = {
            max-length = 40;
            tooltip = false;
          };

          "sway/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
            format = "{name}";
            persistent-workspaces = {
              "1" = [ ];
              "2" = [ ];
              "C" = [ ];
              "E" = [ ];
              "M" = [ ];
            };
          };

          clock = {
            format = "  {:%I:%M %p %Z}";
            format-alt = "󰖟  {:%H:%M UTC}";
            tooltip-format = "{:%A, %B %d, %Y}";
          };

          battery = {
            format = "{icon}  {capacity}%";
            format-charging = "󰂅  {capacity}%";
            format-icons = [
              "󰁺"
              "󰁻"
              "󰁽"
              "󰁿"
              "󰂁"
            ];
            states = {
              warning = 30;
              critical = 15;
            };
          };

          pulseaudio = {
            format = "{icon}  {volume}%";
            format-muted = "󰝟  muted";
            format-icons = {
              default = [
                "󰕿"
                "󰖀"
                "󰕾"
              ];
            };
            on-click = "audio-switcher";
            on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
            on-click-middle = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            scroll-step = 5;
          };
        }
      ];

      style = ''
        * {
          font-family: "${config.sysinit.theme.font.monospace}", "Symbols Nerd Font Mono";
          font-size: 13px;
          font-weight: 500;
          min-height: 0;
          border: none;
          border-radius: 0;
          padding: 0;
          margin: 0;
        }

        window#waybar {
          background-color: alpha(#${c.base00}, 0.85);
          color: #${c.base05};
        }

        tooltip {
          background-color: #${c.base01};
          color: #${c.base05};
          border: 1px solid #${c.base02};
          border-radius: 0;
        }

        #custom-logo {
          padding: 0 12px;
          color: #${c.base0D};
          font-size: 15px;
        }

        #mode {
          padding: 0 10px;
          color: #${c.base00};
          background-color: #${c.base0A};
          font-weight: bold;
        }

        #window {
          padding: 0 10px;
          color: #${c.base04};
          font-style: italic;
        }

        #workspaces button {
          padding: 0 8px;
          color: #${c.base03};
          background: transparent;
        }

        #workspaces button.focused {
          color: #${c.base05};
          font-weight: bold;
          border-bottom: 2px solid #${c.base0D};
        }

        #workspaces button.urgent {
          color: #${c.base00};
          background-color: #${c.base08};
        }

        #workspaces button:hover {
          color: #${c.base05};
          background: alpha(#${c.base02}, 0.5);
        }

        #clock, #battery, #pulseaudio {
          padding: 0 10px;
          color: #${c.base05};
          border-left: 1px solid alpha(#${c.base02}, 0.5);
        }

        #battery.warning { color: #${c.base0A}; }
        #battery.critical { color: #${c.base08}; }
        #battery.charging { color: #${c.base0B}; }
        #pulseaudio.muted { color: #${c.base03}; }
      '';
    };
    rofi = {
      enable = true;
      terminal = "${pkgs.wezterm}/bin/wezterm start";
    };
  };

  home = {
    shellAliases = {
      pbcopy = "wl-copy";
      pbpaste = "wl-paste";
    };
    pointerCursor = {
      name = "macOS";
      package = pkgs.apple-cursor;
      size = 16;
      gtk.enable = true;
    };
    file.".local/share/nemo/actions/open-terminal.nemo_action".text = ''
      [Nemo Action]
      Active=true
      Name=Open Terminal Here
      Exec=wezterm start -e zsh -c "cd %f && zsh"
      Selection=Any
      Extensions=any;
    '';
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = lib.mkForce "prefer-dark";
    };
    "org/cinnamon/desktop/default-applications/terminal".exec = "wezterm";
    "org/nemo/preferences" = {
      show-hidden-files = false;
      show-advanced-permissions = true;
      date-format = "informal";
      default-folder-viewer = "icon-view";
    };
  };
}
