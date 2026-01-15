{
  lib,
  pkgs,
  values,
  ...
}:

let
  themes = import ../../../../shared/lib/theme { inherit lib; };
  semanticColors = themes.getSemanticColors values.theme.colorscheme values.theme.variant;

  # Helper to strip # from hex colors for CSS
  c = color: lib.removePrefix "#" color;

in
{
  # Disable Stylix's waybar theming - using custom theme colors
  stylix.targets.waybar.enable = false;

  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 32;
        spacing = 8;
        margin-top = 6;
        margin-left = 10;
        margin-right = 10;

        modules-left = [
          "hyprland/workspaces"
          "hyprland/window"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "tray"
        ];

        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            urgent = "!";
            default = "-";
          };
          on-click = "activate";
          sort-by-number = true;
        };

        "hyprland/window" = {
          format = "{}";
          max-length = 50;
          separate-outputs = true;
        };

        clock = {
          format = "{:%H:%M}";
          format-alt = "{:%Y-%m-%d %H:%M}";
          tooltip-format = "<tt>{calendar}</tt>";
          calendar = {
            mode = "month";
            format = {
              today = "<span color='#${c semanticColors.accent.primary}'><b>{}</b></span>";
            };
          };
        };

        cpu = {
          format = "CPU {usage}%";
          interval = 2;
        };

        memory = {
          format = "MEM {}%";
          interval = 2;
        };

        network = {
          format-wifi = "WiFi {signalStrength}%";
          format-ethernet = "ETH";
          format-disconnected = "OFF";
          tooltip-format = "{ifname}: {ipaddr}";
        };

        pulseaudio = {
          format = "VOL {volume}%";
          format-muted = "MUTE";
          on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
        };

        tray = {
          spacing = 8;
        };
      };
    };

    style = ''
      * {
        font-family: "${values.theme.font.monospace}", monospace;
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: transparent;
        color: #${c semanticColors.foreground.primary};
      }

      window#waybar.hidden {
        opacity: 0.2;
      }

      #workspaces,
      #window,
      #clock,
      #cpu,
      #memory,
      #network,
      #pulseaudio,
      #tray {
        background: #${c semanticColors.background.primary};
        padding: 0 12px;
        margin: 0 2px;
        border-radius: 8px;
        border: 1px solid #${c semanticColors.background.secondary};
      }

      #workspaces {
        padding: 0 4px;
      }

      #workspaces button {
        padding: 0 8px;
        color: #${c semanticColors.foreground.muted};
        background: transparent;
        border: none;
        border-radius: 6px;
        margin: 4px 2px;
      }

      #workspaces button:hover {
        background: #${c semanticColors.background.secondary};
      }

      #workspaces button.active {
        color: #${c semanticColors.accent.primary};
        background: #${c semanticColors.background.secondary};
      }

      #workspaces button.urgent {
        color: #${c semanticColors.semantic.error};
      }

      #window {
        color: #${c semanticColors.foreground.secondary};
      }

      #clock {
        color: #${c semanticColors.foreground.primary};
        font-weight: bold;
      }

      #cpu,
      #memory {
        color: #${c semanticColors.foreground.muted};
      }

      #network {
        color: #${c semanticColors.semantic.success};
      }

      #network.disconnected {
        color: #${c semanticColors.semantic.error};
      }

      #pulseaudio {
        color: #${c semanticColors.semantic.info};
      }

      #pulseaudio.muted {
        color: #${c semanticColors.foreground.muted};
      }

      #tray {
        padding: 0 8px;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
      }

      tooltip {
        background: #${c semanticColors.background.primary};
        border: 1px solid #${c semanticColors.accent.primary};
        border-radius: 8px;
      }

      tooltip label {
        color: #${c semanticColors.foreground.primary};
      }
    '';
  };
}
