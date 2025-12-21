{
  lib,
  values,
  ...
}:

let
  themes = import ../../../../shared/lib/theme { inherit lib; };
  theme = themes.getTheme values.theme.colorscheme;
  palette = theme.palettes.${values.theme.variant};
  semanticColors = theme.semanticMapping palette;
in
{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 40;
        margin = "8 12 0 12";
        spacing = 10;

        modules-left = [
          "sway/workspaces"
          "sway/mode"
        ];

        modules-center = [
          "sway/window"
        ];

        modules-right = [
          "clock"
          "cpu"
          "memory"
          "temperature"
          "pulseaudio"
          "network"
          "tray"
        ];

        "sway/workspaces" = {
          format = "{icon}";
          on-click = "activate";
          format-icons = {
            "1" = "󰲠";
            "2" = "󰲢";
            "C" = "󰭹";
            "S" = "󰓓";
            default = "󰄛";
          };
        };

        "sway/mode" = {
          format = "{}";
          tooltip = false;
        };

        "sway/window" = {
          format = "{}";
          max-length = 100;
        };

        clock = {
          format = "{:%H:%M}";
          format-alt = "{:%Y-%m-%d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        tray = {
          icon-size = 16;
          spacing = 8;
        };

        cpu = {
          format = " {usage}%";
          tooltip = true;
          interval = 5;
        };

        memory = {
          format = " {used:0.1f}GB";
          tooltip = true;
          interval = 5;
        };

        temperature = {
          format = "󰔏 {temperatureC}°C";
          thermal-zone = 0;
          critical-threshold = 80;
          format-critical = "󰸌 {temperatureC}°C";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰝟";
          format-icons = {
            headphone = "󰋋";
            hands-free = "󰋋";
            headset = "󰋋";
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
          };
          scroll-step = 1;
          on-click = "pavucontrol";
        };

        network = {
          format-wifi = "󰤨 {signalStrength}%";
          format-ethernet = "󰈀";
          format-disconnected = "󰤭";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
          on-click = "nm-connection-editor";
        };
      };
    };

    style = ''
      * {
        font-family: "${values.theme.font.monospace}", monospace;
        font-size: 13px;
        border-radius: 2px;
        min-height: 0;
        padding: 0;
        margin: 0;
      }

      window#waybar {
        background-color: ${semanticColors.background.primary}f0;
        border: 1px solid ${semanticColors.accent.primary}40;
        border-radius: 2px;
        padding: 8px 16px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
      }

      #workspaces {
        background-color: ${semanticColors.background.secondary}60;
        border-radius: 2px;
        padding: 6px 10px;
        margin-right: 16px;
        border: 1px solid ${semanticColors.accent.primary}20;
      }

      #workspaces button {
        color: ${semanticColors.foreground.muted};
        padding: 6px 10px;
        border-radius: 2px;
        margin: 0 4px;
        transition: all 0.3s ease;
        font-size: 16px;
      }

      #workspaces button:hover {
        background-color: ${semanticColors.accent.primary}20;
        color: ${semanticColors.accent.primary};
      }

      #workspaces button.active {
        background-color: ${semanticColors.accent.primary};
        color: ${semanticColors.background.primary};
        border: 1px solid ${semanticColors.accent.primary};
        box-shadow: 0 0 12px ${semanticColors.accent.primary}60;
      }

      #mode {
        background-color: ${semanticColors.semantic.warning}30;
        color: ${semanticColors.semantic.warning};
        padding: 6px 12px;
        border-radius: 2px;
        border: 1px solid ${semanticColors.semantic.warning};
        margin-right: 12px;
      }

      #window {
        color: ${semanticColors.foreground.primary};
        padding: 6px 16px;
        margin: 0 12px;
        background-color: ${semanticColors.background.secondary}40;
        border-radius: 2px;
        flex-grow: 1;
      }

      #clock {
        background-color: ${semanticColors.accent.primary}20;
        color: ${semanticColors.accent.primary};
        padding: 6px 14px;
        margin-left: 8px;
        border-radius: 2px;
        border: 1px solid ${semanticColors.accent.primary}40;
        font-weight: bold;
      }

      #cpu {
        background-color: ${semanticColors.semantic.success}20;
        color: ${semanticColors.semantic.success};
        padding: 6px 12px;
        margin-left: 6px;
        border-radius: 2px;
        border: 1px solid ${semanticColors.semantic.success}40;
      }

      #memory {
        background-color: ${semanticColors.semantic.warning}20;
        color: ${semanticColors.semantic.warning};
        padding: 6px 12px;
        margin-left: 6px;
        border-radius: 2px;
        border: 1px solid ${semanticColors.semantic.warning}40;
      }

      #temperature {
        background-color: ${semanticColors.semantic.info}20;
        color: ${semanticColors.semantic.info};
        padding: 6px 12px;
        margin-left: 6px;
        border-radius: 2px;
        border: 1px solid ${semanticColors.semantic.info}40;
      }

      #temperature.critical {
        background-color: ${semanticColors.semantic.error}40;
        color: ${semanticColors.background.primary};
        border: 1px solid ${semanticColors.semantic.error};
        animation: critical-pulse 1s infinite;
      }

      @keyframes critical-pulse {
        0%, 100% { opacity: 1; }
        50% { opacity: 0.7; }
      }

      #pulseaudio {
        background-color: ${semanticColors.accent.secondary}20;
        color: ${semanticColors.accent.secondary};
        padding: 6px 12px;
        margin-left: 6px;
        border-radius: 2px;
        border: 1px solid ${semanticColors.accent.secondary}40;
      }

      #pulseaudio.muted {
        background-color: ${semanticColors.foreground.muted}20;
        color: ${semanticColors.foreground.muted};
        border-color: ${semanticColors.foreground.muted}40;
      }

      #network {
        background-color: ${semanticColors.semantic.info}20;
        color: ${semanticColors.semantic.info};
        padding: 6px 12px;
        margin-left: 6px;
        border-radius: 2px;
        border: 1px solid ${semanticColors.semantic.info}40;
      }

      #tray {
        background-color: ${semanticColors.background.secondary}60;
        padding: 6px 10px;
        margin-left: 8px;
        border-radius: 6px;
        border: 1px solid ${semanticColors.accent.primary}20;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: ${semanticColors.semantic.warning}20;
      }
    '';
  };
}
