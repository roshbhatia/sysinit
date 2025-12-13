{
  ...
}:

{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        position = "top";
        height = 40;
        spacing = 4;

        modules-left = [
          "niri/workspaces"
          "niri/window"
        ];

        modules-center = [
          "clock"
        ];

        modules-right = [
          "tray"
          "cpu"
          "memory"
          "temperature"
          "pulseaudio"
        ];

        "niri/workspaces" = {
          format = "{name}";
          on-click = "activate";
        };

        "niri/window" = {
          format = "{}";
          max-length = 50;
        };

        clock = {
          format = "{:%H:%M   %a %b %d}";
          format-alt = "{:%Y-%m-%d}";
          on-click-right = "timedatectl set-ntp true";
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
          hwmon-path = "/sys/class/hwmon/hwmon0/temp1_input";
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
      };
    };

    style = ''
      * {
        all: unset;
        font-family: "JetBrains Mono";
        font-size: 12px;
        color: #cdd6f4;
        background-color: #1e1e2e;
      }

      window#waybar {
        background-color: #1e1e2e;
        border-bottom: 1px solid #45475a;
      }

      #workspaces button {
        padding: 5px 10px;
        margin: 5px 2px;
        border-radius: 5px;
      }

      #workspaces button.active {
        background-color: #89b4fa;
        color: #1e1e2e;
      }
    '';
  };
}
