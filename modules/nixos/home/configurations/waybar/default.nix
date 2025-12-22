{
  ...
}:

{
  programs.waybar = {
    enable = false;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 40;
        margin = "8 12 0 12";
        spacing = 10;

        modules-left = [
          "niri/workspaces"
        ];

        modules-center = [
          "niri/window"
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

        "niri/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "󰲠";
            "2" = "󰲢";
            "3" = "󰲤";
            "4" = "󰲦";
            "C" = "󰭹";
            "S" = "󰓓";
            default = "󰄛";
          };
        };

        "niri/window" = {
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
  };
}
