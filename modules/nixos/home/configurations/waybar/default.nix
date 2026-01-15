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
        spacing = 0;
        margin-top = 8;
        margin-left = 16;
        margin-right = 16;
        margin-bottom = 0;

        modules-left = [
          "custom/logo"
          "hyprland/window"
        ];
        modules-center = [ "hyprland/workspaces" ];
        modules-right = [
          "pulseaudio"
          "custom/sep"
          "network"
          "custom/sep"
          "cpu"
          "custom/sep"
          "memory"
          "custom/sep"
          "clock"
          "custom/sep"
          "clock#utc"
          "tray"
        ];

        "custom/logo" = {
          format = "󰣇";
          tooltip = false;
        };

        "custom/sep" = {
          format = "•";
          tooltip = false;
        };

        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            active = "{id}";
            urgent = "!";
            default = "{id}";
          };
          on-click = "activate";
          sort-by-number = true;
          active-only = false;
          all-outputs = true;
        };

        "hyprland/window" = {
          format = "{}";
          max-length = 40;
          separate-outputs = true;
          rewrite = {
            "(.*) — Mozilla Firefox" = "Firefox";
            "(.*) - Visual Studio Code" = "VSCode";
          };
        };

        clock = {
          format = "{:%H:%M}";
          tooltip-format = "<tt>{calendar}</tt>";
          calendar = {
            mode = "month";
            format = {
              today = "<span color='#${c semanticColors.accent.primary}'><b>{}</b></span>";
            };
          };
        };

        "clock#utc" = {
          format = "{:%H:%M UTC}";
          timezone = "UTC";
          tooltip = false;
        };

        cpu = {
          format = "CPU {usage}%";
          interval = 2;
        };

        memory = {
          format = "MEM {percentage}%";
          interval = 2;
        };

        network = {
          format-wifi = "WiFi";
          format-ethernet = "ETH";
          format-disconnected = "OFF";
          tooltip-format-wifi = "{essid} ({signalStrength}%)";
          tooltip-format-ethernet = "{ifname}: {ipaddr}";
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
        font-size: 12px;
        min-height: 0;
        padding: 0;
        margin: 0;
      }

      window#waybar {
        background: #${c semanticColors.background.primary};
        color: #${c semanticColors.foreground.primary};
        border-radius: 10px;
        border: 1px solid #${c semanticColors.background.secondary};
      }

      window#waybar.hidden {
        opacity: 0.2;
      }

      /* All modules get consistent styling */
      #custom-logo,
      #workspaces,
      #window,
      #clock,
      #clock.utc,
      #cpu,
      #memory,
      #network,
      #pulseaudio,
      #tray {
        padding: 0 10px;
      }

      #custom-logo {
        color: #${c semanticColors.accent.primary};
        font-size: 14px;
        padding-left: 12px;
      }

      #custom-sep {
        color: #${c semanticColors.foreground.muted};
        padding: 0 4px;
      }

      /* Workspaces */
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
        min-width: 20px;
      }

      #workspaces button:hover {
        background: #${c semanticColors.background.secondary};
        color: #${c semanticColors.foreground.primary};
      }

      #workspaces button.active {
        color: #${c semanticColors.accent.primary};
        background: #${c semanticColors.background.secondary};
      }

      #workspaces button.urgent {
        color: #${c semanticColors.semantic.error};
      }

      /* Window title */
      #window {
        color: #${c semanticColors.foreground.secondary};
      }

      /* Clock */
      #clock {
        color: #${c semanticColors.foreground.primary};
      }

      #clock.utc {
        color: #${c semanticColors.foreground.muted};
      }

      /* System monitors */
      #cpu,
      #memory {
        color: #${c semanticColors.foreground.muted};
      }

      /* Network */
      #network {
        color: #${c semanticColors.semantic.success};
      }

      #network.disconnected {
        color: #${c semanticColors.semantic.error};
      }

      /* Audio */
      #pulseaudio {
        color: #${c semanticColors.foreground.primary};
      }

      #pulseaudio.muted {
        color: #${c semanticColors.foreground.muted};
      }

      /* Tray */
      #tray {
        padding: 0 8px;
        padding-right: 12px;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
      }

      /* Tooltips */
      tooltip {
        background: #${c semanticColors.background.primary};
        border: 1px solid #${c semanticColors.accent.primary};
        border-radius: 8px;
      }

      tooltip label {
        color: #${c semanticColors.foreground.primary};
        padding: 4px;
      }
    '';
  };
}
