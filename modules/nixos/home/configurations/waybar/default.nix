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
        height = 32;
        margin = "6 12 0 12";
        spacing = 12;

        modules-left = [
          "hyprland/workspaces"
        ];

        modules-center = [
          "hyprland/window"
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

        "hyprland/workspaces" = {
          format = "{name}";
          on-click = "activate";
          all-outputs = false;
        };

        "hyprland/window" = {
          format = "{}";
          max-length = 80;
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
        border-radius: 6px;
        min-height: 0;
        padding: 0;
        margin: 0;
      }

      window#waybar {
        background-color: ${semanticColors.background.primary}cc;
        border: 2px solid ${semanticColors.accent.primary};
        border-radius: 6px;
        padding: 6px 12px;
      }

      #workspaces {
        background-color: ${semanticColors.background.primary}99;
        border-radius: 6px;
        padding: 0 8px;
        margin-right: 12px;
      }

      #workspaces button {
        color: ${semanticColors.foreground.secondary};
        padding: 4px 10px;
        border-radius: 4px;
        margin: 0 2px;
      }

      #workspaces button.active {
        background-color: ${semanticColors.accent.primary};
        color: ${semanticColors.background.primary};
        border: 1px solid ${semanticColors.accent.primary};
      }

      #workspaces button:hover {
        background-color: ${semanticColors.accent.secondary};
      }

      #window {
        color: ${semanticColors.foreground.primary};
        padding: 0 12px;
      }

      #clock,
      #cpu,
      #memory,
      #temperature,
      #pulseaudio,
      #network,
      #tray {
        background-color: ${semanticColors.background.secondary}99;
        color: ${semanticColors.foreground.primary};
        padding: 4px 10px;
        margin-left: 4px;
        border-radius: 4px;
      }

      #clock {
        padding: 4px 12px;
      }

      #temperature.critical {
        background-color: ${semanticColors.semantic.error};
        color: ${semanticColors.background.primary};
      }

      #tray {
        margin-left: 12px;
      }
    '';
  };
}
